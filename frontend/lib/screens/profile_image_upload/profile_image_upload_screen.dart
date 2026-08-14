// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:provider/provider.dart';

import 'widgets/empty_slot.dart';
import 'widgets/filled_slot.dart';
import 'widgets/image_options_sheet.dart';
import 'widgets/photo_tips_sheet.dart';

class ProfileImageUploadScreen extends StatefulWidget {
  const ProfileImageUploadScreen({super.key});

  @override
  State<ProfileImageUploadScreen> createState() =>
      _ProfileImageUploadScreenState();
}

class _ProfileImageUploadScreenState extends State<ProfileImageUploadScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploading = false;
  int? _processingImageId;

  List<UserImage> _images = [];
  static const int _maxImages = 4;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() => _isLoading = true);
    try {
      final images = await _profileRepository.getUserImages();

      // Ensure the primary photo is always at index 0 (the large slot)
      images.sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return 0;
      });

      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<XFile?> _cropImage(XFile image) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
          ),
        ],
      );
      if (croppedFile != null) {
        return XFile(croppedFile.path);
      }
    } catch (e) {
      debugPrint("Error cropping image: $e");
    }
    return null;
  }

  Future<void> _pickAndUploadImage() async {
    if (_images.length >= _maxImages) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (image != null) {
        final croppedImage = await _cropImage(image);
        if (croppedImage != null) {
          setState(() => _isUploading = true);
          await _profileRepository.uploadImage(croppedImage);
          await _fetchImages();
          setState(() => _isUploading = false);
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _setPrimaryImage(int imageId) async {
    setState(() => _processingImageId = imageId);
    try {
      await _profileRepository.setPrimaryImage(imageId);
      await _fetchImages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingImageId = null);
    }
  }

  Future<void> _replaceImage(int imageId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (image != null) {
        final croppedImage = await _cropImage(image);
        if (croppedImage != null) {
          setState(() => _processingImageId = imageId);
          await _profileRepository.replaceImage(imageId, croppedImage);
          await _fetchImages();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingImageId = null);
    }
  }

  Future<void> _deleteImage(int imageId) async {
    setState(() => _processingImageId = imageId);
    try {
      await _profileRepository.deleteImage(imageId);
      await _fetchImages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingImageId = null);
    }
  }

  Future<void> _completeUpload() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 1 photo to continue.'),
        ),
      );
      return;
    }
    final hasPrimary = _images.any((img) => img.isPrimary == true);
    if (!hasPrimary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set one photo as your main photo.'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _profileRepository.completeImageUpload();
      if (mounted) {
        await context.read<AuthProvider>().bootstrap();
      }
      if (mounted) {
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showImageOptions(UserImage image) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => ImageOptionsBottomSheet(
        image: image,
        onSetPrimary: _setPrimaryImage,
        onReplace: _replaceImage,
        onDelete: _deleteImage,
      ),
    );
  }

  void _showPhotoTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PhotoTipsSheet(),
    );
  }

  Widget _buildSlot(int index) {
    final isNextUpload = index == _images.length && _isUploading;

    if (index < _images.length) {
      return FilledSlot(
        image: _images[index],
        slotIndex: index,
        isProcessing: _processingImageId == _images[index].id,
        onTap: () => _showImageOptions(_images[index]),
      );
    } else {
      return EmptySlot(
        slotIndex: index,
        isUploading: isNextUpload,
        onTap: isNextUpload || _isUploading ? null : _pickAndUploadImage,
      );
    }
  }

  Future<void> _handleBackPress() async {
    if (!mounted) return;
    await CustomBottomSheet.show(
      context: context,
      type: BottomSheetType.confirmation,
      title: 'Exit App',
      message: 'Are you sure you want to exit the app?',
      primaryButtonText: 'Exit',
      onPrimaryPressed: () {
        SystemNavigator.pop();
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        context.pop();
      },
      imagePath: 'assets/images/illustrations/exit.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid =
        _images.isNotEmpty &&
        _images.any((img) => img.isPrimary == true);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).dividerColor, width: 1.5),
                ),
                child: Icon(
                  Icons.question_mark_rounded,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                ),
              ),
              onPressed: _showPhotoTips,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _isLoading && _images.isEmpty
              ? Center(
                  child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Header ───────────────────────────────────────
                            Text(
                              'Add your photos',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Upload at least 1 clear photo of yourself. Tap any photo to manage it.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Photo grid ──────────────────────────────────
                            AspectRatio(
                                  aspectRatio:
                                      0.8, // Taller ratio for main photo
                                  child: _buildSlot(0),
                                )
                                .animate()
                                .fade(duration: 400.ms)
                                .slideY(begin: 0.05),

                            const SizedBox(height: 16),

                            Row(
                                  children: [
                                    Expanded(
                                      child: AspectRatio(
                                        aspectRatio: 0.75,
                                        child: _buildSlot(1),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: AspectRatio(
                                        aspectRatio: 0.75,
                                        child: _buildSlot(2),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: AspectRatio(
                                        aspectRatio: 0.75,
                                        child: _buildSlot(3),
                                      ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fade(duration: 500.ms, delay: 100.ms)
                                .slideY(begin: 0.1),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // ── Continue button ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child:
                          CustomButton(
                                text: 'Verify Your Account',
                                onPressed: isValid ? _completeUpload : null,
                                isLoading: _isSaving,
                                height: 52,
                              )
                              .animate(target: isValid ? 1 : 0)
                              .scale(
                                duration: 300.ms,
                                curve: Curves.easeOutBack,
                                begin: const Offset(0.95, 0.95),
                              ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}