import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/user_image.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    setState(() => _isLoading = true);
    try {
      await _profileRepository.setPrimaryImage(imageId);
      await _fetchImages();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _removeImage(int imageId) async {
    setState(() => _isLoading = true);
    try {
      await _profileRepository.removeImage(imageId);
      await _fetchImages();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _completeUpload() async {
    if (_images.length != _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all 4 photos to continue.')),
      );
      return;
    }
    final hasPrimary = _images.any((img) => img.isPrimary == true);
    if (!hasPrimary) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set one photo as your main photo.')),
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
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (image.isPrimary != true)
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.star_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(
                    'Set as Main Photo',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'This will be the first photo people see',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _setPrimaryImage(image.id);
                  },
                ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFE53935), size: 20),
                ),
                title: Text(
                  'Remove Photo',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFE53935),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage(image.id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
      builder: (_) => const _PhotoTipsSheet(),
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

  @override
  Widget build(BuildContext context) {
    final bool isValid = _images.length == _maxImages &&
        _images.any((img) => img.isPrimary == true);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                border: Border.all(color: AppColors.borderColor, width: 1.5),
              ),
              child: const Icon(Icons.question_mark_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
            onPressed: _showPhotoTips,
          ),
          IconButton(
            icon: const Icon(Icons.logout,
                color: AppColors.textSecondary, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isLoading && _images.isEmpty
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary))
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
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Upload 4 clear photos of yourself. Tap any photo to manage it.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Photo grid ──────────────────────────────────
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: _maxImages,
                            itemBuilder: (context, index) {
                              final isNextUpload =
                                  index == _images.length && _isUploading;

                              if (index < _images.length) {
                                return _FilledSlot(
                                  image: _images[index],
                                  slotIndex: index,
                                  onTap: () =>
                                      _showImageOptions(_images[index]),
                                );
                              } else {
                                return _EmptySlot(
                                  slotIndex: index,
                                  isUploading: isNextUpload,
                                  onTap: isNextUpload || _isUploading
                                      ? null
                                      : _pickAndUploadImage,
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 24),


                        ],
                      ),
                    ),
                  ),

                  // ── Continue button ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving || !isValid
                            ? null
                            : _completeUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.borderColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                'Continue',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Filled slot ───────────────────────────────────────────────────────────────
class _FilledSlot extends StatelessWidget {
  final UserImage image;
  final int slotIndex;
  final VoidCallback onTap;

  const _FilledSlot({
    required this.image,
    required this.slotIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = image.isPrimary == true;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Image card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isPrimary
                  ? Border.all(color: AppColors.primary, width: 2.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isPrimary ? 13.5 : 16),
              child: CachedNetworkImage(
                imageUrl: image.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (_, __) => Container(
                  color: AppColors.primaryLight,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          ),

          // Primary badge
          if (isPrimary)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Main Photo',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Edit indicator (top-right)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  color: Colors.white, size: 16),
            ),
          ),

          // Slot number badge (top-left) for non-primary
          if (!isPrimary)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${slotIndex + 1}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty slot ────────────────────────────────────────────────────────────────
class _EmptySlot extends StatelessWidget {
  final int slotIndex;
  final bool isUploading;
  final VoidCallback? onTap;

  const _EmptySlot({
    required this.slotIndex,
    required this.isUploading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMain = slotIndex == 0;
    final label = isMain ? 'Main Photo' : 'Photo ${slotIndex + 1}';

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: isMain ? AppColors.primary : AppColors.borderColor,
          borderRadius: 16,
          dashLength: 7,
          gapLength: 5,
          strokeWidth: isMain ? 1.8 : 1.4,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isMain
                ? AppColors.primary.withValues(alpha: 0.04)
                : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: isUploading
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.primary),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isMain
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.borderColor.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMain
                            ? Icons.add_photo_alternate_outlined
                            : Icons.add_rounded,
                        color: isMain
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: isMain ? 24 : 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: isMain ? FontWeight.w600 : FontWeight.w500,
                        color: isMain
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (isMain) ...[
                      const SizedBox(height: 4),
                      Text(
                        'First impression',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Dashed border painter ─────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    this.strokeWidth = 1.5,
    this.dashLength = 6,
    this.gapLength = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final r = borderRadius;
    final w = size.width;
    final h = size.height;

    // Build the full path of the rounded rectangle
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(r),
    );
    final path = Path()..addRRect(rrect);

    // Measure total path length
    final metrics = path.computeMetrics().toList();

    // Draw dashes
    bool drawing = true;

    for (final metric in metrics) {
      double pos = 0;
      while (pos < metric.length) {
        final remaining = metric.length - pos;
        final segment = math.min(
            drawing ? dashLength : gapLength, remaining);

        if (drawing) {
          final extractedPath = metric.extractPath(pos, pos + segment);
          canvas.drawPath(extractedPath, paint);
        }

        pos += segment;

        if ((drawing && segment >= dashLength) ||
            (!drawing && segment >= gapLength)) {
          drawing = !drawing;
        }
      }
    }

  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.borderRadius != borderRadius;
}



// ── Photo tips bottom sheet ───────────────────────────────────────────────────
class _PhotoTipsSheet extends StatelessWidget {
  const _PhotoTipsSheet();

  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        Icons.face_retouching_natural,
        'Solo shots only for your main',
        'Your first photo should clearly show your face. No group photos — people should immediately know who you are.',
      ),
      (
        Icons.wb_sunny_outlined,
        'Good natural lighting',
        'Bright, natural light is your best friend. Avoid dark, blurry, or heavily shadowed photos.',
      ),
      (
        Icons.no_photography_outlined,
        'No heavy filters',
        'Light edits are fine but avoid heavy filters that alter your appearance. Authenticity matters.',
      ),
      (
        Icons.do_not_disturb_alt_outlined,
        'Skip the sunglasses',
        'Your eyes matter. Remove sunglasses and avoid anything that covers your face.',
      ),
      (
        Icons.photo_library_outlined,
        'Show variety',
        'Mix it up — a close-up portrait, a candid smile, a full-length shot. Let your personality shine.',
      ),
      (
        Icons.history_outlined,
        'Keep it recent',
        'Use photos taken within the last year. People appreciate knowing what you look like today.',
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How to pick great photos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Follow these tips for the best first impression.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: tips.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 28, color: AppColors.borderColor),
                  itemBuilder: (_, i) {
                    final (icon, title, desc) = tips[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon,
                              size: 20, color: AppColors.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
