import 'dart:async';

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

  void registerProfileImageUrl({
    required int? imageId,
    required String? presignedImageUrl,
    bool isBlurred = false,
  }) {
    if (imageId == null || imageId <= 0) return;
    if (presignedImageUrl == null || presignedImageUrl.isEmpty) return;

    _knownUrlsByCacheKey[cacheKeyFor(imageId, isBlurred: isBlurred)] =
        presignedImageUrl;
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
      _knownUrlsByCacheKey.remove(cacheKey);
      try {
        await cacheManager.removeFile(cacheKey);
      } catch (error, stackTrace) {
        debugPrint('Profile image cache eviction failed: $error\n$stackTrace');
      }
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
            registerProfileImageUrl(
              imageId: refreshedUrl.imageId,
              presignedImageUrl: refreshedUrl.presignedImageUrl,
              isBlurred: refreshedUrl.isBlurred,
            );
          }
        }
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
}
