import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/user_image.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/widgets/custom_app_bar.dart';

import '../profile_image_upload/widgets/dashed_border_painter.dart';
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
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        return ImageOptionsBottomSheet(
          image: image,
          onSetPrimary: _setPrimaryImage,
          onRemove: _removeImage,
        );
      },
    );
  }

  Widget _buildSmallSlot(int index) {
    if (index < _images.length) {
      return _SmallImageSlot(
        image: _images[index],
        index: index + 1,
        onTap: () => _showImageOptions(_images[index]),
        isProcessing: _processingImageId == _images[index].id,
      );
    } else {
      return _CustomEmptySlot(onTap: _isUploading ? null : _pickAndUploadImage);
    }
  }

  Widget _buildInfoFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: AppColors.primary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          "You can upload up to 4 photos.",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _images.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: "Manage Photos",
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading && _images.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchImages,
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

  Widget _buildFilledVariant() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _TipCard()
                    .animate()
                    .fade(duration: 350.ms)
                    .slideY(begin: -0.05),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 0.8,
                  child: _PrimaryImageSlot(
                    image: _images[0],
                    onTap: () => _showImageOptions(_images[0]),
                    isProcessing: _processingImageId == _images[0].id,
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
                const _EmptyStateIllustration()
                    .animate()
                    .fade(duration: 400.ms)
                    .scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 32),
                const Text(
                  "No photos yet",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Add photos to your profile to\nget more views and matches.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _pickAndUploadImage,
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
                    backgroundColor: AppColors.primary,
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
                              child: _CustomEmptySlot(
                                onTap: _isUploading
                                    ? null
                                    : _pickAndUploadImage,
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
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF262E3E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(
              Icons.auto_awesome_outlined,
              color: Color(0xFFFFB03A),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tip",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Set a good photo as your primary to get more matches!",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomEmptySlot extends StatelessWidget {
  final VoidCallback? onTap;
  const _CustomEmptySlot({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: AppColors.primary.withValues(alpha: 0.3),
          borderRadius: 16,
          strokeWidth: 1.5,
          dashLength: 6,
          gapLength: 4,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.add, color: AppColors.primary, size: 24),
          ),
        ),
      ),
    );
  }
}

class _PrimaryImageSlot extends StatelessWidget {
  final UserImage image;
  final VoidCallback onTap;
  final bool isProcessing;

  const _PrimaryImageSlot({
    required this.image,
    required this.onTap,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: image.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Primary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.done, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallImageSlot extends StatelessWidget {
  final UserImage image;
  final int index;
  final VoidCallback onTap;
  final bool isProcessing;

  const _SmallImageSlot({
    required this.image,
    required this.index,
    required this.onTap,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: image.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.primary.withValues(alpha: 0.05),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.more_horiz, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateIllustration extends StatelessWidget {
  const _EmptyStateIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEE).withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          Positioned(
            left: 30,
            top: 25,
            child: Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            child: Container(
              width: 90,
              height: 90,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF333333), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF333333),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF333333),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 4,
                            child: CustomPaint(
                              size: const Size(26, 18),
                              painter: _TrianglePainter(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 18,
                            child: CustomPaint(
                              size: const Size(32, 24),
                              painter: _TrianglePainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 1.5,
                    color: const Color(0xFF333333),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 35,
            bottom: 35,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
