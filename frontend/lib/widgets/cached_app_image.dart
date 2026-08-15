import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/services/image_cache_service.dart';

class CachedAppImage extends StatefulWidget {
  final int? imageId;
  final String? presignedImageUrl;
  final bool isBlurred;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Duration fadeInDuration;
  final PlaceholderWidgetBuilder? placeholder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final ImageWidgetBuilder? imageBuilder;

  const CachedAppImage({
    super.key,
    required this.imageId,
    required this.presignedImageUrl,
    this.isBlurred = false,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholder,
    this.errorWidget,
    this.imageBuilder,
  });

  factory CachedAppImage.fromProfileImageMap({
    Key? key,
    required dynamic image,
    double? width,
    double? height,
    BoxFit? fit,
    Alignment alignment = Alignment.center,
    Duration fadeInDuration = const Duration(milliseconds: 300),
    PlaceholderWidgetBuilder? placeholder,
    LoadingErrorWidgetBuilder? errorWidget,
    ImageWidgetBuilder? imageBuilder,
  }) {
    final imageMap = image is Map ? Map<String, dynamic>.from(image) : null;

    return CachedAppImage(
      key: key,
      imageId: _readInt(imageMap?['imageId'] ?? imageMap?['id']),
      presignedImageUrl:
          imageMap?['presignedImageUrl'] as String? ??
          imageMap?['imageUrl'] as String?,
      isBlurred: imageMap?['isBlurred'] as bool? ?? false,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: fadeInDuration,
      placeholder: placeholder,
      errorWidget: errorWidget,
      imageBuilder: imageBuilder,
    );
  }

  @override
  State<CachedAppImage> createState() => _CachedAppImageState();

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class _CachedAppImageState extends State<CachedAppImage> {
  final ImageCacheService _imageCacheService = ImageCacheService.instance;
  late String _currentUrl;
  late bool _effectiveIsBlurred;
  late Future<bool> _cacheProbe;
  bool _hasRetriedWithFreshUrl = false;
  int _renderVersion = 0;

  @override
  void initState() {
    super.initState();
    _resetState();
  }

  @override
  void didUpdateWidget(covariant CachedAppImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageId != widget.imageId ||
        oldWidget.presignedImageUrl != widget.presignedImageUrl ||
        oldWidget.isBlurred != widget.isBlurred) {
      _resetState();
    }
  }

  void _resetState() {
    _currentUrl =
        widget.presignedImageUrl ??
        _imageCacheService.knownProfileImageUrl(
          imageId: widget.imageId,
          isBlurred: widget.isBlurred,
        ) ??
        '';
    _effectiveIsBlurred = widget.isBlurred;
    _hasRetriedWithFreshUrl = false;
    _renderVersion++;

    _imageCacheService.registerProfileImageUrl(
      imageId: widget.imageId,
      presignedImageUrl: widget.presignedImageUrl,
      isBlurred: widget.isBlurred,
    );

    _cacheProbe = _imageCacheService.hasCachedProfileImage(
      imageId: widget.imageId,
      isBlurred: widget.isBlurred,
    );
  }

  Future<void> _refreshAndRetryOnce() async {
    if (_hasRetriedWithFreshUrl) return;

    final imageId = widget.imageId;
    if (imageId == null || imageId <= 0) return;

    _hasRetriedWithFreshUrl = true;
    final refreshedUrl = await _imageCacheService.refreshPresignedUrl(imageId);
    if (!mounted) return;

    final presignedImageUrl = refreshedUrl?.presignedImageUrl;
    if (presignedImageUrl == null || presignedImageUrl.isEmpty) return;

    setState(() {
      _currentUrl = presignedImageUrl;
      _effectiveIsBlurred = refreshedUrl?.isBlurred ?? _effectiveIsBlurred;
      _renderVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageId = widget.imageId;
    if (imageId == null || imageId <= 0) {
      if (_currentUrl.isEmpty) {
        return _buildError(
          context,
          '',
          StateError('Profile image is missing an imageId and URL'),
        );
      }

      return Image.network(
        _currentUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context, _currentUrl);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildError(context, _currentUrl, error);
        },
      );
    }

    final cacheKey = _imageCacheService.cacheKeyFor(
      imageId,
      isBlurred: _effectiveIsBlurred,
    );

    if (_currentUrl.isNotEmpty) {
      return _buildCachedNetworkImage(cacheKey);
    }

    return FutureBuilder<bool>(
      future: _cacheProbe,
      builder: (context, snapshot) {
        final hasCache = snapshot.data == true;

        if (!hasCache &&
            _currentUrl.isEmpty &&
            snapshot.connectionState == ConnectionState.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshAndRetryOnce();
          });
        }

        if (_currentUrl.isEmpty && !hasCache) {
          return _buildPlaceholder(context, '');
        }

        return _buildCachedNetworkImage(cacheKey);
      },
    );
  }

  Widget _buildCachedNetworkImage(String cacheKey) {
    return CachedNetworkImage(
      key: ValueKey('${cacheKey}_$_renderVersion'),
      cacheManager: _imageCacheService.cacheManager,
      imageUrl: _currentUrl.isNotEmpty
          ? _currentUrl
          : _imageCacheService.cacheOnlyUrlFor(cacheKey),
      cacheKey: cacheKey,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      fadeInDuration: widget.fadeInDuration,
      imageBuilder: widget.imageBuilder,
      placeholder: widget.placeholder ?? _buildPlaceholder,
      errorWidget: (context, url, error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshAndRetryOnce();
        });

        return _buildError(context, url, error);
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context, String url) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.withValues(alpha: 0.12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).primaryColor.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String url, Object error) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(context, url, error);
    }

    return Container(
      width: widget.width,
      height: widget.height,
      color: Theme.of(context).primaryColorLight.withValues(alpha: 0.25),
      child: Icon(
        Icons.person_rounded,
        color:
            Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55) ??
            Colors.grey,
      ),
    );
  }
}
