import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:provider/provider.dart';

class OnboardingBackgroundImage extends StatelessWidget {
  final BoxFit fit;
  final Alignment alignment;
  final Color? loadingBackgroundColor;

  const OnboardingBackgroundImage({
    super.key,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.loadingBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ImageAssetProvider>(
      builder: (context, provider, _) {
        final state = provider.getState('ONBOARDING_SCREEN');
        final asset = provider.getFeaturedAsset('ONBOARDING_SCREEN');

        if (asset != null) {
          return CachedNetworkImage(
            imageUrl: asset.imageUrl,
            fit: fit,
            alignment: alignment,
            placeholder: (context, url) => _buildLoadingState(context),
            errorWidget: (context, url, error) => _buildFallbackImage(context),
          );
        }

        if (state == ImageAssetLoadState.loading) {
          return _buildLoadingState(context);
        }

        return _buildFallbackImage(context);
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      color: loadingBackgroundColor ?? Theme.of(context).dividerColor,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    return Image.asset(
      'assets/images/landing_couple.png',
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => Container(
        color: loadingBackgroundColor ?? Theme.of(context).dividerColor,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 48,
        ),
      ),
    );
  }
}
