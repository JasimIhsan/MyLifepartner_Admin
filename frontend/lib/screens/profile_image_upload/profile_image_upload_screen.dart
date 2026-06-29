import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/user_image.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _ProfileImageUploadScreenState extends State<ProfileImageUploadScreen>
    with SingleTickerProviderStateMixin {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploading = false;
  int? _processingImageId;

  List<UserImage> _images = [];
  static const int _maxImages = 4;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _fetchImages();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchImages() async {
    setState(() => _isLoading = true);
    try {
      final images = await _profileRepository.getUserImages();
      // Ensure primary image is always at index 0 (Hero slot)
      images.sort((a, b) {
        if (a.isPrimary == true) return -1;
        if (b.isPrimary == true) return 1;
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

  Future<void> _pickAndUploadImage() async {
    if (_images.length >= _maxImages) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );
      if (image != null) {
        setState(() => _isUploading = true);
        await _profileRepository.uploadImage(image);
        await _fetchImages();
        setState(() => _isUploading = false);
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

  Future<void> _completeUpload() async {
    if (_images.length != _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload all 4 photos to continue.')),
      );
      return;
    }
    final hasPrimary = _images.any((img) => img.isPrimary == true);
    if (!hasPrimary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please set one photo as your main photo.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _profileRepository.completeImageUpload();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SelfieVerificationScreen()),
          (route) => false,
        );
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ImageOptionsBottomSheet(
        image: image,
        onSetPrimary: _setPrimaryImage,
        onRemove: _removeImage,
      ),
    );
  }

  void _showPhotoTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PhotoTipsSheet(),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildPhotoLayout() {
    final bool hasHero = _images.isNotEmpty;
    final bool isUploadingHero = _images.isEmpty && _isUploading;

    return Column(
      children: [
        // Hero Slot (Index 0)
        AspectRatio(
          aspectRatio: 3.2 / 4,
          child: hasHero
              ? FilledSlot(
                  image: _images[0],
                  slotIndex: 0,
                  isProcessing: _processingImageId == _images[0].id,
                  onTap: () => _showImageOptions(_images[0]),
                )
              : EmptySlot(
                  slotIndex: 0,
                  isUploading: isUploadingHero,
                  onTap: isUploadingHero || _isUploading
                      ? null
                      : _pickAndUploadImage,
                ),
        ),
        const SizedBox(height: 16),
        // Secondary Slots (Indexes 1, 2, 3)
        Row(
          children: List.generate(3, (i) {
            final index = i + 1;
            final isNextUpload = index == _images.length && _isUploading;

            Widget slot;
            if (index < _images.length) {
              slot = FilledSlot(
                image: _images[index],
                slotIndex: index,
                isProcessing: _processingImageId == _images[index].id,
                onTap: () => _showImageOptions(_images[index]),
              );
            } else {
              slot = EmptySlot(
                slotIndex: index,
                isUploading: isNextUpload,
                onTap:
                    isNextUpload || _isUploading ? null : _pickAndUploadImage,
              );
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 8,
                  right: i == 2 ? 0 : 8,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: slot,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isValid = _images.length == _maxImages &&
        _images.any((img) => img.isPrimary == true);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: IconButton(
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.6),
                    border: Border.all(
                        color: AppColors.borderColor.withValues(alpha: 0.5),
                        width: 1),
                  ),
                  child: const Icon(Icons.question_mark_rounded,
                      size: 16, color: AppColors.textPrimary),
                ),
                onPressed: _showPhotoTips,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout,
                color: AppColors.textPrimary, size: 22),
            onPressed: _logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Premium Animated Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFAFAFA),
                    AppColors.primaryLight.withValues(alpha: 0.08),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: _isLoading && _images.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Header ───────────────────────────────────────
                                  const Text(
                                    'Add your photos',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Upload 4 clear photos of yourself. Tap any photo to manage it.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // ── Hero & Secondary Photo Grid ─────────────────
                                  _buildPhotoLayout(),

                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isValid
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: _isSaving || !isValid ? null : _completeUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.borderColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
