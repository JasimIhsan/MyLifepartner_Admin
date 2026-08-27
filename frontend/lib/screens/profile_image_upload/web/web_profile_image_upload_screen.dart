// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../widgets/empty_slot.dart';
import '../widgets/filled_slot.dart';
import '../widgets/image_options_sheet.dart';
import '../widgets/photo_tips_sheet.dart';

class WebProfileImageUploadScreen extends StatefulWidget {
  const WebProfileImageUploadScreen({super.key});

  @override
  State<WebProfileImageUploadScreen> createState() =>
      _WebProfileImageUploadScreenState();
}

class _WebProfileImageUploadScreenState
    extends State<WebProfileImageUploadScreen> {
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
      _sortImages(images);
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
          IOSUiSettings(title: 'Crop Image'),
          WebUiSettings(context: context, presentStyle: WebPresentStyle.dialog),
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
          final updatedImage = await _profileRepository.replaceImage(
            imageId,
            croppedImage,
          );
          _replaceImageLocally(updatedImage);
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

  void _replaceImageLocally(UserImage updatedImage) {
    if (!mounted) return;
    final imageIndex = _images.indexWhere(
      (image) => image.imageId == updatedImage.imageId,
    );
    if (imageIndex == -1) return;
    final nextImages = List<UserImage>.from(_images);
    nextImages[imageIndex] = updatedImage;
    _sortImages(nextImages);
    setState(() => _images = nextImages);
  }

  void _sortImages(List<UserImage> imagesToSort) {
    imagesToSort.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return 0;
    });
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
      if (mounted) setState(() => _isSaving = false);
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
      onPrimaryPressed: () => SystemNavigator.pop(),
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () => context.pop(),
      imagePath: 'assets/images/illustrations/exit.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid =
        _images.isNotEmpty && _images.any((img) => img.isPrimary == true);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1024) {
              return _buildTabletLayout(context, isValid);
            }
            final leftWidth = constraints.maxWidth < 1280 ? 340.0 : 400.0;
            return _buildDesktopLayout(context, isValid, leftWidth);
          },
        ),
      ),
    );
  }

  // ─── Tablet Layout ──────────────────────────────────────────────────────────
  Widget _buildTabletLayout(BuildContext context, bool isValid) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header bar
        Container(
          color: theme.cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Image.asset(
                  theme.brightness == Brightness.dark
                      ? 'assets/icons/app_logo_dark.png'
                      : 'assets/icons/app_logo.png',
                  height: 30,
                  width: 30,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.favorite_rounded,
                    color: theme.primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Life Partner Again',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showPhotoTips,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.question_mark_rounded,
                        size: 16,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(height: 1, color: theme.dividerColor),

        // Content
        Expanded(
          child: _isLoading && _images.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    color: theme.primaryColor,
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                        child: _buildPhotoGrid(context),
                      ),
                    ),
                  ),
                ),
        ),

        // Continue button
        _buildContinueBar(context, isValid, padding: 28),
      ],
    );
  }

  // ─── Desktop Layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(
    BuildContext context,
    bool isValid,
    double leftWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLeftPanel(context, leftWidth),
        Expanded(child: _buildRightPanel(context, isValid)),
      ],
    );
  }

  Widget _buildLeftPanel(BuildContext context, double width) {
    final primary = Theme.of(context).primaryColor;
    final uploadedCount = _images.length;
    final hasPrimary = _images.any((img) => img.isPrimary);

    return Container(
      width: width,
      color: primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 44, 44, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/icons/app_logo_dark.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Text(
                    'Life Partner Again',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Section pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PROFILE PHOTOS',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Add your\nbest photos',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your photos are your first impression. Upload clear, recent photos that show your face. You can add up to $_maxImages photos.',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 15,
                      height: 1.65,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Upload status
                  _buildUploadStatus(uploadedCount, hasPrimary),

                  const SizedBox(height: 36),

                  // Tips button
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _showPhotoTips,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            color: Colors.white.withValues(alpha: 0.65),
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Photo tips',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(44, 0, 44, 36),
              child: Text(
                '© Life Partner Again',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStatus(int uploadedCount, bool hasPrimary) {
    final items = [
      (
        uploadedCount > 0,
        '$uploadedCount of $_maxImages photo${uploadedCount == 1 ? '' : 's'} uploaded',
      ),
      (hasPrimary, 'Main photo selected'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items.map((item) {
        final (done, label) = item;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  border: done
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                ),
                child: done
                    ? Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: done
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRightPanel(BuildContext context, bool isValid) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: _isLoading && _images.isEmpty
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(48, 56, 48, 32),
                          child: _buildPhotoGrid(context),
                        ),
                      ),
                    ),
                  ),
          ),
          _buildContinueBar(context, isValid, padding: 48),
        ],
      ),
    );
  }

  // ─── Shared photo grid ──────────────────────────────────────────────────────
  Widget _buildPhotoGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add your photos',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap any slot to upload. Tap a photo to manage it.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),

        // Main photo (large)
        AspectRatio(
              aspectRatio: 0.85,
              child: _buildSlot(0),
            )
            .animate()
            .fade(duration: 400.ms)
            .slideY(begin: 0.05),

        const SizedBox(height: 14),

        // Three secondary photos
        Row(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.78,
                    child: _buildSlot(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.78,
                    child: _buildSlot(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.78,
                    child: _buildSlot(3),
                  ),
                ),
              ],
            )
            .animate()
            .fade(duration: 500.ms, delay: 100.ms)
            .slideY(begin: 0.1),

        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Continue button bar ────────────────────────────────────────────────────
  Widget _buildContinueBar(
    BuildContext context,
    bool isValid, {
    required double padding,
  }) {
    final theme = Theme.of(context);
    final isActive = isValid && !_isSaving;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(padding, 20, padding, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedOpacity(
            opacity: isValid ? 1.0 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: MouseRegion(
                cursor: isActive
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: ElevatedButton(
                  onPressed: isActive ? _completeUpload : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.primaryColor,
                    disabledForegroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Verify Your Account',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
