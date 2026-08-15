import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/services/image_url_service.dart';

class S3CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Duration fadeInDuration;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const S3CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<S3CachedImage> createState() => _S3CachedImageState();
}

class _S3CachedImageState extends State<S3CachedImage> {
  late String _currentUrl;
  bool _isRetrying = false;
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.imageUrl;
  }

  @override
  void didUpdateWidget(covariant S3CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _currentUrl = widget.imageUrl;
      _retryKey++;
    }
  }

  String get _cacheKey {
    try {
      final uri = Uri.parse(widget.imageUrl);
      return uri.replace(query: '').toString();
    } catch (e) {
      return widget.imageUrl;
    }
  }

  Future<void> _handleError() async {
    if (_isRetrying) return;
    _isRetrying = true;
    try {
      final newUrl = await ImageUrlService.getPresignedUrl(_cacheKey);
      if (newUrl != null && newUrl.isNotEmpty && mounted) {
        setState(() {
          _currentUrl = newUrl;
          _retryKey++;
        });
      }
    } finally {
      if (mounted) {
        _isRetrying = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: ValueKey('${_cacheKey}_$_retryKey'),
      imageUrl: _currentUrl,
      cacheKey: _cacheKey,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      fadeInDuration: widget.fadeInDuration,
      placeholder: widget.placeholder,
      errorWidget: (context, url, error) {
        // If it fails, attempt a retry once (or let the _handleError control it)
        if (!_isRetrying) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleError();
          });
        }
        if (widget.errorWidget != null) {
          return widget.errorWidget!(context, url, error);
        }
        return const Icon(Icons.error);
      },
    );
  }
}

class S3CachedImageProvider extends CachedNetworkImageProvider {
  S3CachedImageProvider(
    super.url, {
    super.maxHeight,
    super.maxWidth,
    super.scale,
  }) : super(cacheKey: _extractCacheKey(url));

  static String _extractCacheKey(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.replace(query: '').toString();
    } catch (e) {
      return url;
    }
  }
}
