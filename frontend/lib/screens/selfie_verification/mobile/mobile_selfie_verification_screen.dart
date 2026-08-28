// ignore_for_file: unused_import

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/screens/selfie_verification/widgets/face_direction_overlay.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mobile selfie verification screen — identical logic and UI, just renamed.
/// Used by AdaptiveScreen when width < 800.
class MobileSelfieVerificationScreen extends StatefulWidget {
  const MobileSelfieVerificationScreen({super.key});

  @override
  State<MobileSelfieVerificationScreen> createState() =>
      _MobileSelfieVerificationScreenState();
}

class _MobileSelfieVerificationScreenState
    extends State<MobileSelfieVerificationScreen>
    with WidgetsBindingObserver {
  final ProfileRepository _profileRepository = ProfileRepository();
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _isPermissionDenied = false;
  bool _isCapturing = false;
  String? _errorMessage;
  bool _hasDeniedLocation = false;

  XFile? _frontImage;
  XFile? _leftImage;
  XFile? _rightImage;

  int _currentStep = 0;
  int _previewIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
    _checkLocationPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized) _initCamera();
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          _hasDeniedLocation = false;
        }
      });
    }
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
          setState(() {
            _isCameraInitialized = true;
            _isPermissionDenied = false;
            _errorMessage = null;
          });
        }
      } else {
        setState(() => _errorMessage = 'No cameras available');
      }
    } catch (e) {
      bool isPermissionError = false;
      if (e is CameraException) {
        if (e.code == 'cameraPermission' ||
            e.code == 'CameraAccessDenied' ||
            e.code == 'permissionDenied') {
          isPermissionError = true;
        }
      }
      if (e.toString().toLowerCase().contains('permission')) {
        isPermissionError = true;
      }
      if (isPermissionError) {
        setState(() {
          _isPermissionDenied = true;
          _errorMessage =
              'Camera access is required for verification. Please grant camera access in settings.';
        });
      } else {
        setState(() => _errorMessage = 'Failed to initialize camera: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      await HapticFeedback.mediumImpact();
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
          _currentStep = 3;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to take picture: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _submitVerification() async {
    if (_frontImage == null || _leftImage == null || _rightImage == null) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw 'Location services are disabled. Please enable them in settings.';
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (mounted) setState(() {});
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _hasDeniedLocation = true;
          _isLoading = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await _profileRepository.uploadSelfie(
        _frontImage!,
        _leftImage!,
        _rightImage!,
        position.latitude,
        position.longitude,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selfieStatus', 'PENDING');
      await prefs.setString('profileStatus', 'COMPLETED');
      await prefs.setBool('locationVerified', true);
      if (mounted) {
        await context.read<AuthProvider>().bootstrap();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
    }
  }

  void _retakeAll() {
    if (_isLoading) return;
    setState(() {
      _frontImage = _leftImage = _rightImage = null;
      _currentStep = 0;
    });
  }

  XFile? get _currentImage {
    if (_currentStep == 3) {
      switch (_previewIndex) {
        case 0:
          return _frontImage;
        case 1:
          return _leftImage;
        case 2:
          return _rightImage;
        default:
          return _frontImage;
      }
    }
    switch (_currentStep) {
      case 0:
        return _frontImage;
      case 1:
        return _leftImage;
      case 2:
        return _rightImage;
      default:
        return _frontImage;
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
          width: previewH,
          height: previewW,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Future<void> _handleBackPress() async {
    if (!mounted || _isLoading) return;
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

  void _showTips() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _SelfieTipsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double circleDia = (MediaQuery.of(context).size.width * 0.78).clamp(
      0.0,
      320.0,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).canvasColor,
          elevation: 0,
          leading: const SizedBox.shrink(),
          actions: [
            IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.question_mark_rounded,
                  size: 16,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
              ),
              onPressed: _showTips,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Verify your identity',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color ??
                                  AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take a clear selfie to help us keep\nthe community safe and authentic.',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color ??
                                  AppColors.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color:
                                      Theme.of(context).textTheme.bodyLarge?.color ??
                                      AppColors.textPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your selfies are only used for verification and will remain secure. We also request location service access when submitting the selfies.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: SizedBox(
                                  width: circleDia + 10,
                                  height: circleDia + 10,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: circleDia + 10,
                                        height: circleDia + 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: (_currentImage != null ||
                                                    _isCameraInitialized)
                                                ? Theme.of(context).textTheme.bodyLarge
                                                        ?.color ??
                                                    AppColors.textPrimary.withValues(
                                                      alpha: 0.2,
                                                    )
                                                : Theme.of(context).dividerColor,
                                            width: 5,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: circleDia,
                                        height: circleDia,
                                        decoration:
                                            const BoxDecoration(shape: BoxShape.circle),
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
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          _isPermissionDenied
                                                              ? Icons.videocam_off_outlined
                                                              : Icons.error_outline,
                                                          color:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.color ??
                                                              AppColors.textSecondary,
                                                          size: 32,
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Text(
                                                          _errorMessage!,
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color:
                                                                Theme.of(context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.color ??
                                                                AppColors.textSecondary,
                                                          ),
                                                          textAlign: TextAlign.center,
                                                        ),
                                                        if (_isPermissionDenied) ...[
                                                          const SizedBox(height: 16),
                                                          ElevatedButton(
                                                            onPressed: () async {
                                                              await Geolocator
                                                                  .openAppSettings();
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Theme.of(
                                                                context,
                                                              ).primaryColor,
                                                              foregroundColor: Theme.of(
                                                                context,
                                                              ).colorScheme.onPrimary,
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal: 20,
                                                                    vertical: 10,
                                                                  ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(20),
                                                              ),
                                                              elevation: 0,
                                                            ),
                                                            child: const Text(
                                                              'Grant Access',
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).textTheme.bodyLarge?.color ??
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      if (_currentStep < 3 && _isCameraInitialized)
                                        IgnorePointer(
                                          child: FaceDirectionOverlay(
                                            step: _currentStep,
                                            size: circleDia,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_currentStep < 3) ...[
                            _buildShutterButton(),
                          ] else ...[
                            _buildPreviewThumbnails(),
                            const SizedBox(height: 32),
                            _hasDeniedLocation
                                ? _PrimaryButton(
                                    label: 'Grant Location Access',
                                    onPressed: () async {
                                      await Geolocator.openAppSettings();
                                    },
                                  )
                                : _PrimaryButton(
                                    label: 'Complete Verification',
                                    isLoading: _isLoading,
                                    onPressed: _isLoading ? null : _submitVerification,
                                  ),
                            const SizedBox(height: 14),
                            TextButton(
                              onPressed: _isLoading ? null : _retakeAll,
                              child: Text(
                                'Retake All',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: _isLoading
                                      ? (Theme.of(context).textTheme.bodyMedium?.color ??
                                                AppColors.textSecondary)
                                            .withValues(alpha: 0.4)
                                      : Theme.of(context).textTheme.bodyMedium?.color ??
                                            AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    final bool isEnabled = _isCameraInitialized && !_isLoading && !_isCapturing;
    return GestureDetector(
      onTap: isEnabled ? _takeSelfie : null,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isEnabled
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withValues(alpha: 0.3),
              width: 4,
            ),
          ),
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColor.withValues(alpha: 0.3),
            ),
            child: _isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    Icons.camera_alt_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewThumbnails() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildThumbnail(0, 'Front', _frontImage),
        const SizedBox(width: 16),
        _buildThumbnail(1, 'Left', _leftImage),
        const SizedBox(width: 16),
        _buildThumbnail(2, 'Right', _rightImage),
      ],
    );
  }

  Widget _buildThumbnail(int index, String label, XFile? image) {
    if (image == null) return const SizedBox();
    final isSelected = _previewIndex == index;
    return GestureDetector(
      onTap: _isLoading ? null : () => setState(() => _previewIndex = index),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
                width: isSelected ? 3 : 1,
              ),
              image: kIsWeb
                  ? null
                  : DecorationImage(
                      image: FileImage(File(image.path)),
                      fit: BoxFit.cover,
                    ),
            ),
            child: kIsWeb
                ? ClipOval(
                    child: Image.network(
                      image.path,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color ??
                        AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tips bottom sheet (shared) ───────────────────────────────────────────────
class _SelfieTipsSheet extends StatelessWidget {
  const _SelfieTipsSheet();

  @override
  Widget build(BuildContext context) {
    const tips = [
      (
        Icons.wb_sunny_outlined,
        'Good lighting',
        'Face a window or light source. Avoid harsh shadows.',
      ),
      (
        Icons.face_retouching_natural,
        'Face the camera',
        'Look directly into the lens. Keep your face centred.',
      ),
      (
        Icons.do_not_disturb_alt_outlined,
        'No filters or glasses',
        'Remove sunglasses and avoid heavy filters.',
      ),
      (
        Icons.sentiment_satisfied_alt,
        'Neutral expression',
        'A relaxed expression works best. Just be yourself.',
      ),
      (
        Icons.crop_free,
        'Stay within the circle',
        'Keep your head centred inside the circular frame.',
      ),
      (
        Icons.no_photography_outlined,
        'No photos of photos',
        "Don't photograph a picture on screen. Take a live selfie.",
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'How to take a great selfie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Follow these tips for a quick approval.',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  controller: ctrl,
                  itemCount: tips.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 28,
                    color: Theme.of(context).dividerColor,
                  ),
                  itemBuilder: (_, i) {
                    final (icon, title, desc) = tips[i];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color ??
                                      AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      AppColors.textSecondary,
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
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

// ─── Reusable primary button ──────────────────────────────────────────────────
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
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: Theme.of(context).dividerColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
