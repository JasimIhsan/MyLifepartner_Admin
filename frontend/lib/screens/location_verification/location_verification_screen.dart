import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationVerificationScreen extends StatefulWidget {
  final XFile front;
  final XFile left;
  final XFile right;
  final VoidCallback onSuccess;

  const LocationVerificationScreen({
    super.key,
    required this.front,
    required this.left,
    required this.right,
    required this.onSuccess,
  });

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _requestAndSubmitLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them in settings.';
      }

      // 2. Check & request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permission permanently denied.\nPlease enable it in app settings.';
      }

      // 3. Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      // 4. Send to backend
      // await _profileRepository.uploadVerificationSelfiesAndLocation(
      //   front: widget.front,
      //   left: widget.left,
      //   right: widget.right,
      //   latitude: position.latitude,
      //   longitude: position.longitude,
      // );

      // 5. Mark as pending / success
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selfieStatus', 'PENDING');
      await prefs.setBool('locationVerified', true);

      widget.onSuccess();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? 'Verification failed')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Location Verification',
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'We need your location',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This helps us verify your identity and show relevant matches near you.\n\nLocation is only used for verification and matching — we never share it publicly.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _requestAndSubmitLocation,
                icon: _isLoading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.location_searching, color: Colors.white),
                label: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Allow Location & Complete',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
