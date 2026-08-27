import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/screens/profile_image_upload/widgets/dashed_border_painter.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

class CustomEmptySlot extends StatelessWidget {
  final VoidCallback? onTap;
  const CustomEmptySlot({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          borderRadius: 16,
          strokeWidth: 1.5,
          dashLength: 6,
          gapLength: 4,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class PrimaryImageSlot extends StatelessWidget {
  final UserImage image;
  final VoidCallback onTap;
  final VoidCallback onManageTap;
  final Widget? customManageButton;
  final bool isProcessing;

  const PrimaryImageSlot({
    super.key,
    required this.image,
    required this.onTap,
    required this.onManageTap,
    this.customManageButton,
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
            CachedAppImage(
              imageId: image.imageId,
              presignedImageUrl: image.presignedImageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                child: Icon(
                  Icons.broken_image_outlined,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
              ),
            ),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF74B72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, color: Colors.white, size: 14),
                    SizedBox(width: 6),
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
            Positioned(
              top: 12,
              right: 12,
              child: customManageButton ?? GestureDetector(
                onTap: onManageTap,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.black87,
                    size: 16,
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

class SmallImageSlot extends StatelessWidget {
  final UserImage image;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onManageTap;
  final Widget? customManageButton;
  final bool isProcessing;

  const SmallImageSlot({
    super.key,
    required this.image,
    required this.index,
    required this.onTap,
    required this.onManageTap,
    this.customManageButton,
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
            CachedAppImage(
              imageId: image.imageId,
              presignedImageUrl: image.presignedImageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                child: Icon(
                  Icons.broken_image_outlined,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
              ),
            ),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: customManageButton ?? GestureDetector(
                onTap: onManageTap,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    color: Colors.black87,
                    size: 16,
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

class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({super.key});

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
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
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

class CustomWebCropperDialog extends StatefulWidget {
  final Widget cropper;
  final void Function() initCropper;
  final Future<String?> Function() crop;

  const CustomWebCropperDialog({
    super.key,
    required this.cropper,
    required this.initCropper,
    required this.crop,
  });

  @override
  State<CustomWebCropperDialog> createState() => _CustomWebCropperDialogState();
}

class _CustomWebCropperDialogState extends State<CustomWebCropperDialog> {
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure the dialog and HtmlElementView are fully mounted in the DOM
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        widget.initCropper();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Crop Photo",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.cropper,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isCropping
                      ? null
                      : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isCropping
                      ? null
                      : () async {
                          setState(() => _isCropping = true);
                          try {
                            final result = await widget.crop();
                            if (!context.mounted) return;
                            Navigator.of(context).pop(result);
                          } catch (e) {
                            debugPrint("Crop error: $e");
                            if (mounted) {
                              setState(() => _isCropping = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isCropping
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Crop Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
