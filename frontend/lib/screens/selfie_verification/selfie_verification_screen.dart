import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_app_bar.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        // Find front camera if available
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
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
          });
        }
      } else {
        setState(() {
          _errorMessage = "No cameras available";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to initialize camera: $e";
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _selfieImage = image;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _retakeSelfie() {
    setState(() {
      _selfieImage = null;
    });
  }

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
          MaterialPageRoute(builder: (context) => const HomePage()),
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
          SnackBar(
            content: Text(_errorMessage ?? 'Upload failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: "Selfie Verification",
        leading: SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              final sharedPrefs = await SharedPreferences.getInstance();
              await sharedPrefs.clear();
              if (mounted) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Verify your profile",
                style: TextStyle(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Please take a clear selfie to verify your identity. This helps keep our community safe.",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Image Preview or Placeholder
              Expanded(
                child: Center(
                  child: Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selfieImage != null || _isCameraInitialized
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _selfieImage != null
                          ? (kIsWeb
                                ? Image.network(
                                    _selfieImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_selfieImage!.path),
                                    fit: BoxFit.cover,
                                  ))
                          : (_isCameraInitialized
                                ? CameraPreview(_cameraController!)
                                : const Center(
                                    child: CircularProgressIndicator(),
                                  )),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              if (_errorMessage != null &&
                  _selfieImage == null &&
                  !_isCameraInitialized)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_selfieImage == null)
                CustomButton(
                  onPressed: _isCameraInitialized ? _takeSelfie : null,
                  text: "Capture Selfie",
                  backgroundColor: AppColors.primary,
                  height: 50,
                )
              else
                Column(
                  children: [
                    CustomButton(
                      onPressed: _isLoading ? null : _uploadSelfie,
                      isLoading: _isLoading,
                      text: "Upload & Verify",
                      backgroundColor: AppColors.primary,
                      height: 50,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading ? null : _retakeSelfie,
                      child: const Text(
                        "Retake Selfie",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
