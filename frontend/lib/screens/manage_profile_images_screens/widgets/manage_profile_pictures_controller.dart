import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/profile_image_upload/widgets/image_options_sheet.dart';

mixin ManageProfilePicturesControllerState<T extends StatefulWidget>
    on State<T> {
  final ProfileRepository profileRepository = ProfileRepository();
  final ImagePicker picker = ImagePicker();

  bool isLoading = false;
  bool isUploading = false;
  int? processingImageId;
  String? errorMessage;

  List<UserImage> images = [];
  final int maxImages = 4;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetchedImages = await profileRepository.getUserImages();

      // Ensure the primary photo is always at index 0 (the large slot)
      fetchedImages.sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          images = fetchedImages;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching images: $e');
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> pickAndUploadImage() async {
    if (images.length >= maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $maxImages images allowed.')),
      );
      return;
    }

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => isUploading = true);
        await profileRepository.uploadImage(image);
        await fetchImages();
        setState(() => isUploading = false);
      }
    } catch (e) {
      setState(() {
        isUploading = false;
        errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> setPrimaryImage(int imageId) async {
    setState(() => processingImageId = imageId);
    try {
      await profileRepository.setPrimaryImage(imageId);
      await fetchImages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => processingImageId = null);
    }
  }

  Future<void> replaceImage(int imageId) async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => processingImageId = imageId);
        await profileRepository.replaceImage(imageId, image);
        await fetchImages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => processingImageId = null);
    }
  }

  void showImageOptions(UserImage image) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return ImageOptionsBottomSheet(
          image: image,
          onSetPrimary: setPrimaryImage,
          onReplace: replaceImage,
        );
      },
    );
  }
}
