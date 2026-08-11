import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/custom_app_bar.dart';

import '../widgets/manage_profile_pictures_controller.dart';
import '../widgets/manage_profile_pictures_ui_helpers.dart';

class MobileManageProfilePicturesScreen extends StatefulWidget {
  const MobileManageProfilePicturesScreen({super.key});

  @override
  State<MobileManageProfilePicturesScreen> createState() =>
      _MobileManageProfilePicturesScreenState();
}

class _MobileManageProfilePicturesScreenState
    extends State<MobileManageProfilePicturesScreen>
    with
        ManageProfilePicturesControllerState<
          MobileManageProfilePicturesScreen
        > {
  Widget _buildSmallSlot(int index) {
    if (index < images.length) {
      return SmallImageSlot(
        image: images[index],
        index: index + 1,
        onTap: () => showImageOptions(images[index]),
        isProcessing: processingImageId == images[index].id,
      );
    } else {
      return CustomEmptySlot(onTap: isUploading ? null : pickAndUploadImage);
    }
  }

  Widget _buildInfoFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          "You can upload up to 4 photos.",
          style: TextStyle(
            fontSize: 12,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilledVariant() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 0.8,
                  child: PrimaryImageSlot(
                    image: images[0],
                    onTap: () => showImageOptions(images[0]),
                    isProcessing: processingImageId == images[0].id,
                  ),
                ).animate().fade(duration: 400.ms).slideY(begin: 0.05),
                const SizedBox(height: 16),
                Row(
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 0.75,
                            child: _buildSmallSlot(1),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 0.75,
                            child: _buildSmallSlot(2),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 0.75,
                            child: _buildSmallSlot(3),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fade(duration: 500.ms, delay: 100.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 32),
                _buildInfoFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyVariant() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const EmptyStateIllustration()
                    .animate()
                    .fade(duration: 400.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 32),
                Text(
                  "No photos yet",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Add photos to your profile to\nget more views and matches.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: pickAndUploadImage,
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: const Text(
                    "Add Photos",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                ).animate().scale(delay: 200.ms, duration: 250.ms),
                const SizedBox(height: 60),
                Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: AspectRatio(
                            aspectRatio: 0.75,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < 3 ? 12.0 : 0,
                              ),
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
                const SizedBox(height: 28),
                _buildInfoFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: CustomAppBar(
        title: "Manage Photos",
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
          onPressed: () {
            context.pop(true);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
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
            : hasImages
            ? _buildFilledVariant()
            : _buildEmptyVariant(),
      ),
    );
  }
}
