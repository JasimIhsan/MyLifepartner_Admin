import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState
    extends State<SelfieVerificationScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isCameraInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;
  XFile? _selfieImage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      } else {
        setState(() => _errorMessage = 'No cameras available');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _selfieImage = image;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take picture: $e')),
        );
      }
    }
  }

  void _retakeSelfie() => setState(() => _selfieImage = null);

  Future<void> _uploadSelfie() async {
    if (_selfieImage == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _profileRepository.uploadSelfie(_selfieImage!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selfieStatus', 'PENDING');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Upload failed')),
        );
      }
    }
  }

  // CameraPreview returns previewSize in landscape pixels even on portrait
  // devices, so swap width/height then let FittedBox cover-fill the circle.
  Widget _buildCameraFill(double size) {
    final preview = _cameraController!.value.previewSize;
    // previewSize is landscape on both Android & iOS — the longer side is width
    final previewW = preview?.width ?? size;
    final previewH = preview?.height ?? size;
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          // Swap so portrait phone fills correctly
          width: previewH,
          height: previewW,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SelfieTipsSheet(),
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
    // Circle diameter = 78 % of screen width, capped
    final double circleDia =
        (MediaQuery.of(context).size.width * 0.78).clamp(0.0, 320.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          // Help / tips button
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.borderColor, width: 1.5),
              ),
              child: const Icon(Icons.question_mark_rounded,
                  size: 16, color: AppColors.textSecondary),
            ),
            onPressed: _showTips,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Title
              Text(
                'Verify your identity',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Take a clear selfie to help us keep\nthe community safe and authentic.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // ── Circular frame ──────────────────────────────────────
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Container(
                        width: circleDia + 10,
                        height: circleDia + 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_selfieImage != null ||
                                    _isCameraInitialized)
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.borderColor,
                            width: 5,
                          ),
                        ),
                      ),
                      // Main circle
                      Container(
                        width: circleDia,
                        height: circleDia,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (_selfieImage != null ||
                                    _isCameraInitialized)
                                ? AppColors.primary
                                : AppColors.borderColor,
                            width: 2,
                          ),
                          color: AppColors.primaryLight,
                        ),
                        child: ClipOval(
                          child: _selfieImage != null
                              ? (kIsWeb
                                  ? Image.network(
                                      _selfieImage!.path,
                                      width: circleDia,
                                      height: circleDia,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selfieImage!.path),
                                      width: circleDia,
                                      height: circleDia,
                                      fit: BoxFit.cover,
                                    ))
                              : (_isCameraInitialized
                                  ? _buildCameraFill(circleDia)
                                  : _errorMessage != null
                                      ? Center(
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.all(24),
                                            child: Text(
                                              _errorMessage!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color:
                                                    AppColors.textSecondary,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Buttons ──────────────────────────────────────────────
              if (_selfieImage == null) ...[
                _PrimaryButton(
                  label: 'Take Selfie',
                  onPressed: _isCameraInitialized ? _takeSelfie : null,
                ),
              ] else ...[
                _PrimaryButton(
                  label: 'Submit & Verify',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _uploadSelfie,
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _isLoading ? null : _retakeSelfie,
                  child: Text(
                    'Retake',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tips bottom sheet ─────────────────────────────────────────────────────────
class _SelfieTipsSheet extends StatelessWidget {
  const _SelfieTipsSheet();

  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        Icons.wb_sunny_outlined,
        'Good lighting',
        'Face a window or a light source. Avoid harsh shadows or very bright backlighting.',
      ),
      (
        Icons.face_retouching_natural,
        'Face the camera',
        'Look directly into the lens. Keep your face centred and fully visible.',
      ),
      (
        Icons.do_not_disturb_alt_outlined,
        'No filters or glasses',
        'Remove sunglasses and avoid heavy filters. Your face should be clearly recognisable.',
      ),
      (
        Icons.sentiment_satisfied_alt,
        'Neutral expression',
        'A relaxed, natural expression works best. No need to smile — just be yourself.',
      ),
      (
        Icons.crop_free,
        'Stay within the circle',
        'Keep your head centred inside the circular frame, with a little space around the top of your head.',
      ),
      (
        Icons.no_photography_outlined,
        'No photos of photos',
        "Don't photograph a picture on screen or paper. Take a live selfie only.",
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
                'How to take a great selfie',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Follow these tips for a quick approval.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: tips.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 28, color: AppColors.borderColor),
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

// ── Reusable primary button ───────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.borderColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
