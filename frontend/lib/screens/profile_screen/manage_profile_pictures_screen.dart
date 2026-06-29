import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/user_image.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_app_bar.dart';

import '../profile_image_upload/widgets/empty_slot.dart';
import '../profile_image_upload/widgets/filled_slot.dart';
import '../profile_image_upload/widgets/image_options_sheet.dart';

class ManageProfilePicturesScreen extends StatefulWidget {
  const ManageProfilePicturesScreen({super.key});

  @override
  State<ManageProfilePicturesScreen> createState() =>
      _ManageProfilePicturesScreenState();
}

class _ManageProfilePicturesScreenState
    extends State<ManageProfilePicturesScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isUploading = false;
  int? _processingImageId;
  String? _errorMessage;

  List<UserImage> _images = [];
  final int _maxImages = 4;

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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
      debugPrint('Error fetching images: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
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

  Future<void> _pickAndUploadImage() async {
    if (_images.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $_maxImages images allowed.')),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        await _profileRepository.uploadImage(image);
        await _fetchImages();
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = e.toString();
      });
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

  Future<void> _removeImage(int imageId) async {
    setState(() => _processingImageId = imageId);
    try {
      await _profileRepository.removeImage(imageId);
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

  void _showImageOptions(UserImage image) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return ImageOptionsBottomSheet(
          image: image,
          onSetPrimary: _setPrimaryImage,
          onRemove: _removeImage,
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CustomAppBar(
        title: "Manage Photos",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(
              context,
              true,
            ); // Return true to indicate potential changes
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _images.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Manage your profile photos.",
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Tap an image to set it as primary or delete it. You can have up to 4 photos.",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AspectRatio(
                                aspectRatio: 0.8, // Taller ratio for main photo
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
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
