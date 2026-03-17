import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/screens/location_verification/location_verification_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// NEW: Import the location screen

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isCameraInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  XFile? _frontImage;
  XFile? _leftImage;
  XFile? _rightImage;

  int _currentStep = 0; // 0=front, 1=left, 2=right, 3=all done

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
        if (mounted) setState(() => _isCameraInitialized = true);
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
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        if (_currentStep == 0) {
          _frontImage = image;
          _currentStep = 1;
        } else if (_currentStep == 1) {
          _leftImage = image;
          _currentStep = 2;
        } else if (_currentStep == 2) {
          _rightImage = image;
          _currentStep = 3; // All selfies taken → show submit
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take picture: $e')));
      }
    }
  }

  Future<void> _goToLocationScreen() async {
    if (_frontImage == null || _leftImage == null || _rightImage == null)
      return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationVerificationScreen(
          front: _frontImage!,
          left: _leftImage!,
          right: _rightImage!,
          onSuccess: () async {
            // Optional: mark onboarding done
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboardingCompleted', true);
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            }
          },
        ),
      ),
    );

    if (result != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location access is required to complete verification'),
          duration: Duration(seconds: 4),
        ),
      );
    }
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

  void _retakeAll() {
    setState(() {
      _frontImage = _leftImage = _rightImage = null;
      _currentStep = 0;
    });
  }

  String get _title {
    switch (_currentStep) {
      case 0:
        return "Take Front Face";
      case 1:
        return "Turn Left (Profile)";
      case 2:
        return "Turn Right (Profile)";
      case 3:
        return "All selfies captured!";
      default:
        return "";
    }
  }

  XFile? get _currentImage {
    switch (_currentStep) {
      case 0:
        return _frontImage;
      case 1:
        return _leftImage;
      case 2:
        return _rightImage;
      default:
        return _frontImage; // fallback to front when done
    }
  }

  Widget _buildCameraFill(double size) {
    final preview = _cameraController!.value.previewSize;
    final previewW = preview?.width ?? size;
    final previewH = preview?.height ?? size;
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewH, // swapped for portrait
          height: previewW,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  // ... keep _showTips(), _logout(), _SelfieTipsSheet, _PrimaryButton as they are ...

  @override
  Widget build(BuildContext context) {
    final double circleDia = (MediaQuery.of(context).size.width * 0.78).clamp(
      0.0,
      320.0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
              child: const Icon(
                Icons.question_mark_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
            onPressed: _showTips,
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: AppColors.textSecondary,
              size: 20,
            ),
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
              const SizedBox(height: 8),
              Text(
                _title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.primary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: circleDia + 10,
                        height: circleDia + 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                (_currentImage != null || _isCameraInitialized)
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.borderColor,
                            width: 5,
                          ),
                        ),
                      ),
                      Container(
                        width: circleDia,
                        height: circleDia,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                (_currentImage != null || _isCameraInitialized)
                                ? AppColors.primary
                                : AppColors.borderColor,
                            width: 2,
                          ),
                          color: AppColors.primaryLight,
                        ),
                        child: ClipOval(
                          child: _currentImage != null
                              ? (kIsWeb
                                    ? Image.network(
                                        _currentImage!.path,
                                        width: circleDia,
                                        height: circleDia,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_currentImage!.path),
                                        width: circleDia,
                                        height: circleDia,
                                        fit: BoxFit.cover,
                                      ))
                              : _isCameraInitialized
                              ? _buildCameraFill(circleDia)
                              : _errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
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
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (_currentStep < 3) ...[
                _PrimaryButton(
                  label: 'Take Selfie',
                  onPressed: _isCameraInitialized && !_isLoading
                      ? _takeSelfie
                      : null,
                ),
              ] else ...[
                _PrimaryButton(
                  label: 'Continue to Location',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _goToLocationScreen,
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: _retakeAll,
                  child: Text(
                    'Retake All',
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
                          child: Icon(icon, size: 20, color: AppColors.primary),
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
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
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
