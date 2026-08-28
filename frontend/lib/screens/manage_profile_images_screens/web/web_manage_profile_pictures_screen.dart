import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

import '../widgets/manage_profile_pictures_controller.dart';
import '../widgets/manage_profile_pictures_ui_helpers.dart';

class WebManageProfilePicturesScreen extends StatefulWidget {
  const WebManageProfilePicturesScreen({super.key});

  @override
  State<WebManageProfilePicturesScreen> createState() =>
      _WebManageProfilePicturesScreenState();
}

class _WebManageProfilePicturesScreenState
    extends State<WebManageProfilePicturesScreen>
    with ManageProfilePicturesControllerState<WebManageProfilePicturesScreen> {
  void _showImagePreview(UserImage image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedAppImage(
                imageId: image.imageId,
                presignedImageUrl: image.presignedImageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  showImageOptions(image);
                },
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text(
                  "Manage Photo",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebManageButton(UserImage image) {
    return PopupMenuButton<String>(
      tooltip: 'Manage Photo',
      offset: const Offset(0, 32),
      color: Theme.of(context).canvasColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      onSelected: (value) {
        if (value == 'primary') {
          setPrimaryImage(image.id);
        } else if (value == 'replace')
          replaceImage(image.id);
        else if (value == 'delete')
          deleteImage(image.id);
      },
      itemBuilder: (context) => [
        if (!image.isPrimary)
          const PopupMenuItem(
            value: 'primary',
            child: Row(
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFF74B72), size: 20),
                SizedBox(width: 12),
                Text(
                  'Set as Main Photo',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'replace',
          child: Row(
            children: [
              Icon(Icons.sync_rounded, color: Color(0xFFF74B72), size: 20),
              SizedBox(width: 12),
              Text(
                'Replace Photo',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
        if (!image.isPrimary)
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text(
                  'Delete Photo',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.more_horiz, color: Colors.black87, size: 16),
      ),
    );
  }

  Widget _buildSmallSlot(int index) {
    if (index < images.length) {
      return SmallImageSlot(
        image: images[index],
        index: index + 1,
        onTap: () => _showImagePreview(images[index]),
        onManageTap: () {},
        customManageButton: _buildWebManageButton(images[index]),
        isProcessing: processingImageId == images[index].id,
      );
    } else {
      return CustomEmptySlot(onTap: isUploading ? null : pickAndUploadImage);
    }
  }

  Widget _buildInfoFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          "Click on any photo to preview or manage.",
          style: TextStyle(
            fontSize: 14,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFilledVariant() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Profile Image Management",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${images.length} ",
                        style: const TextStyle(
                          color: Color(0xFFF74B72),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextSpan(
                        text: "/ $maxImages Photos",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Upload up to $maxImages photos. One must be primary.",
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                const spacing = 16.0;
                final columnWidth = (totalWidth - 2 * spacing) / 3;
                final rowHeight = columnWidth;
                final leftImageHeight = 2 * rowHeight + spacing;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: columnWidth,
                      height: leftImageHeight,
                      child: PrimaryImageSlot(
                        image: images[0],
                        onTap: () => _showImagePreview(images[0]),
                        onManageTap: () {},
                        customManageButton: _buildWebManageButton(images[0]),
                        isProcessing: processingImageId == images[0].id,
                      ),
                    ).animate().fade(duration: 400.ms).slideX(begin: -0.05),
                    const SizedBox(width: spacing),
                    SizedBox(
                      width: columnWidth * 2 + spacing,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                    width: columnWidth,
                                    height: rowHeight,
                                    child: _buildSmallSlot(1),
                                  )
                                  .animate()
                                  .fade(duration: 500.ms, delay: 100.ms)
                                  .slideX(begin: 0.05),
                              const SizedBox(width: spacing),
                              SizedBox(
                                    width: columnWidth,
                                    height: rowHeight,
                                    child: _buildSmallSlot(2),
                                  )
                                  .animate()
                                  .fade(duration: 500.ms, delay: 200.ms)
                                  .slideX(begin: 0.05),
                            ],
                          ),
                          const SizedBox(height: spacing),
                          SizedBox(
                                width: columnWidth * 2 + spacing,
                                height: rowHeight,
                                child: _buildSmallSlot(3),
                              )
                              .animate()
                              .fade(duration: 500.ms, delay: 300.ms)
                              .slideY(begin: 0.05),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            _buildInfoFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVariant() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyStateIllustration()
                .animate()
                .fade(duration: 400.ms)
                .scale(begin: const Offset(0.9, 0.9)),
            const SizedBox(height: 32),
            Text(
              "No photos yet",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Add photos to your profile to get more views and matches.\nHigh-quality photos increase your match rate by up to 5x.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    AppColors.textSecondary.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: pickAndUploadImage,
              icon: const Icon(
                Icons.add_photo_alternate,
                color: Colors.white,
                size: 24,
              ),
              label: const Text(
                "Upload Your First Photo",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ).animate().scale(delay: 200.ms, duration: 250.ms),
            const SizedBox(height: 60),
            Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: Padding(
                          padding: EdgeInsets.only(right: index < 3 ? 16.0 : 0),
                          child: CustomEmptySlot(
                            onTap: isUploading ? null : pickAndUploadImage,
                          ),
                        ),
                      ),
                    );
                  }),
                )
                .animate()
                .fade(duration: 500.ms, delay: 300.ms)
                .slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: SafeArea(
        child: isLoading && images.isEmpty
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchImages,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(40),
                child: hasImages ? _buildFilledVariant() : _buildEmptyVariant(),
              ),
      ),
    );
  }
}
