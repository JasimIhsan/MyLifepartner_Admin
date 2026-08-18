import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:life_partner_again/services/api_service.dart';

class ProfileImageUrl {
  final int imageId;
  final String? presignedImageUrl;
  final bool isBlurred;

  const ProfileImageUrl({
    required this.imageId,
    required this.presignedImageUrl,
    this.isBlurred = false,
  });

  factory ProfileImageUrl.fromJson(Map<String, dynamic> json) {
    return ProfileImageUrl(
      imageId: _readInt(json['imageId'] ?? json['id']) ?? 0,
      presignedImageUrl:
          json['presignedImageUrl'] as String? ?? json['imageUrl'] as String?,
      isBlurred: json['isBlurred'] as bool? ?? false,
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ProfileImageCachePreparation {
  final Future<void> future;
  final bool canUseCacheImmediately;

  const ProfileImageCachePreparation._({
    required this.future,
    required this.canUseCacheImmediately,
  });

  factory ProfileImageCachePreparation.immediate() {
    return ProfileImageCachePreparation._(
      future: SynchronousFuture<void>(null),
      canUseCacheImmediately: true,
    );
  }

  factory ProfileImageCachePreparation.deferred(Future<void> future) {
    return ProfileImageCachePreparation._(
      future: future,
      canUseCacheImmediately: false,
    );
  }
}

class ImageCacheService {
  ImageCacheService._();

  static final ImageCacheService instance = ImageCacheService._();

  static const Duration _refreshBatchDelay = Duration(milliseconds: 25);

  final CacheManager cacheManager = CacheManager(
    Config(
      'lifePartnerProfileImages',
      stalePeriod: const Duration(days: 45),
      maxNrOfCacheObjects: 1200,
    ),
  );

  final Dio _client = ApiService.client;
  final Map<String, String> _knownUrlsByCacheKey = {};
  final Map<String, String> _contentFingerprintsByCacheKey = {};
  final Map<String, Future<void>> _pendingCachePreparations = {};
  final Map<int, Completer<ProfileImageUrl?>> _pendingRefreshes = {};
  final Set<int> _queuedRefreshImageIds = {};
  Timer? _refreshBatchTimer;

  String cacheKeyFor(int imageId, {bool isBlurred = false}) {
    return isBlurred
        ? 'profile_image_${imageId}_blurred'
        : 'profile_image_$imageId';
  }

  String cacheOnlyUrlFor(String cacheKey) {
    return 'https://local.life-partner-again.invalid/$cacheKey';
  }

  ProfileImageCachePreparation prepareProfileImageUrl({
    required int? imageId,
    required String? presignedImageUrl,
    bool isBlurred = false,
  }) {
    if (imageId == null || imageId <= 0) {
      return ProfileImageCachePreparation.immediate();
    }

    final normalizedUrl = _normalizeUrl(presignedImageUrl);
    if (normalizedUrl == null) {
      return ProfileImageCachePreparation.immediate();
    }

    final cacheKey = cacheKeyFor(imageId, isBlurred: isBlurred);
    final newFingerprint = _contentFingerprintForUrl(normalizedUrl);
    final knownUrl = _knownUrlsByCacheKey[cacheKey];
    final knownFingerprint =
        _contentFingerprintsByCacheKey[cacheKey] ??
        _contentFingerprintForUrl(knownUrl);

    if (knownFingerprint != null && newFingerprint != null) {
      if (knownFingerprint == newFingerprint) {
        _rememberProfileImageUrl(cacheKey, normalizedUrl, newFingerprint);
        return ProfileImageCachePreparation.immediate();
      }

      final future =
          _evictCacheKey(cacheKey, urlsToEvict: [knownUrl, normalizedUrl]).then(
            (_) {
              _rememberProfileImageUrl(cacheKey, normalizedUrl, newFingerprint);
            },
          );

      return ProfileImageCachePreparation.deferred(future);
    }

    final preparationKey = '$cacheKey::$newFingerprint';
    final pendingPreparation = _pendingCachePreparations[preparationKey];
    if (pendingPreparation != null) {
      return ProfileImageCachePreparation.deferred(pendingPreparation);
    }

    final future = _prepareProfileImageUrl(
      cacheKey: cacheKey,
      presignedImageUrl: normalizedUrl,
      contentFingerprint: newFingerprint,
      knownUrl: knownUrl,
    );
    _pendingCachePreparations[preparationKey] = future;
    future.whenComplete(() {
      if (_pendingCachePreparations[preparationKey] == future) {
        _pendingCachePreparations.remove(preparationKey);
      }
    });

    return ProfileImageCachePreparation.deferred(future);
  }

  void registerProfileImageUrl({
    required int? imageId,
    required String? presignedImageUrl,
    bool isBlurred = false,
  }) {
    if (imageId == null || imageId <= 0) return;
    final normalizedUrl = _normalizeUrl(presignedImageUrl);
    if (normalizedUrl == null) return;

    _rememberProfileImageUrl(
      cacheKeyFor(imageId, isBlurred: isBlurred),
      normalizedUrl,
      _contentFingerprintForUrl(normalizedUrl),
    );
  }

  String? knownProfileImageUrl({
    required int? imageId,
    bool isBlurred = false,
  }) {
    if (imageId == null || imageId <= 0) return null;

    return _knownUrlsByCacheKey[cacheKeyFor(imageId, isBlurred: isBlurred)];
  }

  Future<bool> hasCachedProfileImage({
    required int? imageId,
    bool isBlurred = false,
  }) async {
    if (imageId == null || imageId <= 0) return false;

    try {
      final cachedFile = await cacheManager.getFileFromCache(
        cacheKeyFor(imageId, isBlurred: isBlurred),
      );
      return cachedFile != null;
    } catch (error, stackTrace) {
      debugPrint('Profile image cache lookup failed: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> evictProfileImage(int imageId) async {
    if (imageId <= 0) return;

    final clearKeys = [
      cacheKeyFor(imageId),
      cacheKeyFor(imageId, isBlurred: true),
    ];

    for (final cacheKey in clearKeys) {
      await _evictCacheKey(cacheKey);
    }
  }

  Future<ProfileImageUrl?> refreshPresignedUrl(int imageId) {
    if (imageId <= 0) return Future.value(null);

    final existingRefresh = _pendingRefreshes[imageId];
    if (existingRefresh != null) {
      return existingRefresh.future;
    }

    final completer = Completer<ProfileImageUrl?>();
    _pendingRefreshes[imageId] = completer;
    _queuedRefreshImageIds.add(imageId);
    _refreshBatchTimer ??= Timer(_refreshBatchDelay, _flushRefreshBatch);

    return completer.future;
  }

  void _flushRefreshBatch() {
    _refreshBatchTimer = null;
    final imageIds = Set<int>.from(_queuedRefreshImageIds);
    _queuedRefreshImageIds.clear();

    if (imageIds.isEmpty) return;

    _loadFreshUrls(imageIds);
  }

  Future<void> _loadFreshUrls(Set<int> imageIds) async {
    final refreshedById = <int, ProfileImageUrl>{};
    final cachePreparationFutures = <Future<void>>[];

    try {
      final response = await _client.post(
        '/profile/images/presigned-urls',
        data: {'imageIds': imageIds.toList()},
      );

      final data = response.data?['data'];
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;

          final refreshedUrl = ProfileImageUrl.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (refreshedUrl.imageId > 0) {
            refreshedById[refreshedUrl.imageId] = refreshedUrl;
            cachePreparationFutures.add(
              prepareProfileImageUrl(
                imageId: refreshedUrl.imageId,
                presignedImageUrl: refreshedUrl.presignedImageUrl,
                isBlurred: refreshedUrl.isBlurred,
              ).future,
            );
          }
        }
      }

      if (cachePreparationFutures.isNotEmpty) {
        await Future.wait(cachePreparationFutures);
      }
    } catch (error, stackTrace) {
      debugPrint('Bulk profile image URL refresh failed: $error\n$stackTrace');
    } finally {
      for (final imageId in imageIds) {
        final completer = _pendingRefreshes.remove(imageId);
        if (completer != null && !completer.isCompleted) {
          completer.complete(refreshedById[imageId]);
        }
      }
    }
  }

  Future<void> _prepareProfileImageUrl({
    required String cacheKey,
    required String presignedImageUrl,
    required String? contentFingerprint,
    required String? knownUrl,
  }) async {
    String? cachedOriginalUrl;
    String? cachedFingerprint;

    try {
      final cachedFile = await cacheManager.getFileFromCache(cacheKey);
      cachedOriginalUrl = cachedFile?.originalUrl;
      cachedFingerprint = _contentFingerprintForUrl(cachedOriginalUrl);
    } catch (error, stackTrace) {
      debugPrint(
        'Profile image cache metadata lookup failed: $error\n$stackTrace',
      );
    }

    if (contentFingerprint != null &&
        cachedFingerprint != null &&
        contentFingerprint != cachedFingerprint) {
      await _evictCacheKey(
        cacheKey,
        urlsToEvict: [knownUrl, cachedOriginalUrl, presignedImageUrl],
      );
    }

    _rememberProfileImageUrl(cacheKey, presignedImageUrl, contentFingerprint);
  }

  Future<void> _evictCacheKey(
    String cacheKey, {
    Iterable<String?> urlsToEvict = const [],
  }) async {
    final knownUrl = _knownUrlsByCacheKey.remove(cacheKey);
    _contentFingerprintsByCacheKey.remove(cacheKey);

    final providerUrls = <String>{
      cacheOnlyUrlFor(cacheKey),
      if (_normalizeUrl(knownUrl) != null) _normalizeUrl(knownUrl)!,
      for (final url in urlsToEvict)
        if (_normalizeUrl(url) != null) _normalizeUrl(url)!,
    };

    for (final url in providerUrls) {
      try {
        await CachedNetworkImageProvider(
          url,
          cacheManager: cacheManager,
          cacheKey: cacheKey,
        ).evict();
      } catch (error, stackTrace) {
        debugPrint('Flutter image cache eviction failed: $error\n$stackTrace');
      }
    }

    try {
      await cacheManager.removeFile(cacheKey);
    } catch (error, stackTrace) {
      debugPrint('Profile image cache eviction failed: $error\n$stackTrace');
    }
  }

  void _rememberProfileImageUrl(
    String cacheKey,
    String presignedImageUrl,
    String? contentFingerprint,
  ) {
    _knownUrlsByCacheKey[cacheKey] = presignedImageUrl;
    if (contentFingerprint != null) {
      _contentFingerprintsByCacheKey[cacheKey] = contentFingerprint;
    }
  }

  String? _normalizeUrl(String? url) {
    final trimmedUrl = url?.trim();
    if (trimmedUrl == null || trimmedUrl.isEmpty) return null;
    return trimmedUrl;
  }

  String? _contentFingerprintForUrl(String? url) {
    final normalizedUrl = _normalizeUrl(url);
    if (normalizedUrl == null) return null;

    try {
      final uri = Uri.parse(normalizedUrl);
      if (!uri.hasScheme || uri.host.isEmpty) return normalizedUrl;
      return uri.replace(query: '', fragment: '').toString();
    } catch (_) {
      return normalizedUrl;
    }
  }
}
