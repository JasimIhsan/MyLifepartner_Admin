import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/custom_app_bar.dart';

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
          size: 18,
          color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Text(
          "You can upload up to 4 photos. We recommend high-quality portraits.",
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilledVariant() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 0.8,
                    child: PrimaryImageSlot(
                      image: images[0],
                      onTap: () => showImageOptions(images[0]),
                      isProcessing: processingImageId == images[0].id,
                    ),
                  ).animate().fade(duration: 400.ms).slideX(begin: -0.05),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      AspectRatio(aspectRatio: 1.0, child: _buildSmallSlot(1))
                          .animate()
                          .fade(duration: 500.ms, delay: 100.ms)
                          .slideX(begin: 0.05),
                      const SizedBox(height: 24),
                      AspectRatio(aspectRatio: 1.0, child: _buildSmallSlot(2))
                          .animate()
                          .fade(duration: 500.ms, delay: 200.ms)
                          .slideX(begin: 0.05),
                      const SizedBox(height: 24),
                      AspectRatio(aspectRatio: 1.0, child: _buildSmallSlot(3))
                          .animate()
                          .fade(duration: 500.ms, delay: 300.ms)
                          .slideX(begin: 0.05),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
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
                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Add photos to your profile to get more views and matches.\nHigh-quality photos increase your match rate by up to 5x.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary.withValues(alpha: 0.8),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: "Manage Photos",
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary),
          onPressed: () {
            context.pop(true);
          },
        ),
      ),
      body: SafeArea(
        child: isLoading && images.isEmpty
            ? Center(
                child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
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
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
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