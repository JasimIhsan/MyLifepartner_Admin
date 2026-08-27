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

/// Web / tablet selfie verification screen.
/// Same logic as the mobile screen but with a responsive two-column layout
/// on desktop (≥ 1024px) and a centered single-column layout on tablet (< 1024px).
class WebSelfieVerificationScreen extends StatefulWidget {
  const WebSelfieVerificationScreen({super.key});

  @override
  State<WebSelfieVerificationScreen> createState() =>
      _WebSelfieVerificationScreenState();
}

class _WebSelfieVerificationScreenState
    extends State<WebSelfieVerificationScreen>
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

  // ─── Step labels ─────────────────────────────────────────────────────────
  static const _stepLabels = ['Front', 'Left', 'Right', 'Review'];
  static const _stepInstructions = [
    'Look straight into the camera',
    'Turn your head to the left',
    'Turn your head to the right',
    'Review your photos before submitting',
  ];

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
      bool isPermissionError = e is CameraException &&
          (e.code == 'cameraPermission' ||
              e.code == 'CameraAccessDenied' ||
              e.code == 'permissionDenied');
      if (e.toString().toLowerCase().contains('permission')) {
        isPermissionError = true;
      }
      if (isPermissionError) {
        setState(() {
          _isPermissionDenied = true;
          _errorMessage =
              'Camera access is required for verification. Please grant camera access in your browser or system settings.';
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

  void _showTips(BuildContext context) {
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
              return _buildTabletLayout(context);
            }
            final leftWidth = constraints.maxWidth < 1280 ? 340.0 : 400.0;
            return _buildDesktopLayout(context, leftWidth);
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLET LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTabletLayout(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
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
                    onTap: () => _showTips(context),
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: _buildCameraContent(context, cameraSize: 320),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktopLayout(BuildContext context, double leftWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLeftPanel(context, leftWidth),
        Expanded(
          child: _buildRightContent(context),
        ),
      ],
    );
  }

  Widget _buildLeftPanel(BuildContext context, double width) {
    final primary = Theme.of(context).primaryColor;
    final stepLabels = _stepLabels;

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
                      'IDENTITY VERIFICATION',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Animated step title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        )),
                        child: child,
                      ),
                    ),
                    child: Align(
                      key: ValueKey('title_$_currentStep'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _currentStep < 3
                            ? 'Photo ${_currentStep + 1} of 3'
                            : 'Review & Submit',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    ),
                    child: Align(
                      key: ValueKey('desc_$_currentStep'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _stepInstructions[_currentStep.clamp(0, 3)],
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 15,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Step progress indicators
                  Row(
                    children: List.generate(3, (index) {
                      final isDone = index < _currentStep;
                      final isCurrent = index == _currentStep;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDone || isCurrent
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                stepLabels[index],
                                style: GoogleFonts.outfit(
                                  color: isDone || isCurrent
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 40),

                  // Privacy note
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your selfies are only used for verification and remain secure.',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Tips link
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _showTips(context),
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
                            'Selfie tips',
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

  Widget _buildRightContent(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 48, 48, 48),
              child: _buildCameraContent(context, cameraSize: 320),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Shared camera content ──────────────────────────────────────────────────
  Widget _buildCameraContent(BuildContext context, {required double cameraSize}) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Camera / preview circle
        _buildCameraCircle(context, cameraSize),

        const SizedBox(height: 36),

        // Step instruction text (tablet / right panel)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            key: ValueKey(_currentStep),
            _stepInstructions[_currentStep.clamp(0, 3)],
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 32),

        if (_currentStep < 3) ...[
          _buildShutterButton(context),
        ] else ...[
          _buildPreviewThumbnails(context),
          const SizedBox(height: 32),
          _buildActionButton(context),
          const SizedBox(height: 14),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: TextButton(
              onPressed: _isLoading ? null : _retakeAll,
              child: Text(
                'Retake All',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _isLoading
                      ? (theme.textTheme.bodyMedium?.color ??
                                AppColors.textSecondary)
                              .withValues(alpha: 0.4)
                      : theme.textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCameraCircle(BuildContext context, double size) {
    final theme = Theme.of(context);
    final hasContent = _currentImage != null || _isCameraInitialized;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: hasContent
                  ? theme.primaryColor.withValues(alpha: 0.3)
                  : theme.dividerColor,
              width: 5,
            ),
          ),
        ),

        // Camera / image circle
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: ClipOval(
            child: _currentImage != null
                ? (kIsWeb
                      ? Image.network(
                          _currentImage!.path,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_currentImage!.path),
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        ))
                : _isCameraInitialized
                ? _buildCameraFill(size)
                : _errorMessage != null
                ? _buildErrorState(context)
                : Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
          ),
        ),

        // Direction overlay
        if (_currentStep < 3 && _isCameraInitialized)
          IgnorePointer(
            child: FaceDirectionOverlay(step: _currentStep, size: size),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isPermissionDenied
                  ? Icons.videocam_off_outlined
                  : Icons.error_outline,
              color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color:
                    theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isPermissionDenied) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async => Geolocator.openAppSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Grant Access',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShutterButton(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEnabled = _isCameraInitialized && !_isLoading && !_isCapturing;

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
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
                    ? theme.primaryColor
                    : theme.primaryColor.withValues(alpha: 0.3),
                width: 4,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled
                    ? theme.primaryColor
                    : theme.primaryColor.withValues(alpha: 0.3),
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
                      color: theme.colorScheme.onPrimary,
                      size: 26,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = !_isLoading;

    return _hasDeniedLocation
        ? SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () async => Geolocator.openAppSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Grant Location Access',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        : SizedBox(
            width: double.infinity,
            height: 54,
            child: MouseRegion(
              cursor: isActive
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: ElevatedButton(
                onPressed: isActive ? _submitVerification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: theme.dividerColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Complete Verification',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_outline, size: 18),
                        ],
                      ),
              ),
            ),
          );
  }

  Widget _buildPreviewThumbnails(BuildContext context) {
    final theme = Theme.of(context);
    final thumbs = [
      (0, 'Front', _frontImage),
      (1, 'Left', _leftImage),
      (2, 'Right', _rightImage),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: thumbs.map((t) {
        final (index, label, image) = t;
        if (image == null) return const SizedBox();
        final isSelected = _previewIndex == index;
        return Padding(
          padding: EdgeInsets.only(right: index < 2 ? 16 : 0),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => setState(() => _previewIndex = index),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.primaryColor
                            : theme.dividerColor,
                        width: isSelected ? 3 : 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: kIsWeb
                          ? Image.network(
                              image.path,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(image.path),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? theme.primaryColor
                          : theme.textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Tips bottom sheet ────────────────────────────────────────────────────────
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
