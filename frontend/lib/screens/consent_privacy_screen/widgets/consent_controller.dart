import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/services/auth_repository.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../consent_privacy_screen.dart';
import 'full_text_screen.dart';

mixin ConsentControllerState<T extends StatefulWidget> on State<T> {
  bool isLoading = true;
  bool isRegistering = false;

  bool termsAccepted = false;
  bool privacyAcknowledged = false;

  String? termsVersion;
  String? privacyVersion;
  String termsContent = "Loading terms...";
  String privacyContent = "Loading privacy policy...";
  String? authErrorMessage;

  ConsentPrivacyScreen get consentWidget => widget as ConsentPrivacyScreen;

  @override
  void initState() {
    super.initState();
    _fetchLegalDocuments();
  }

  Future<void> _fetchLegalDocuments() async {
    try {
      final termsResponse = await ApiService.client.get("/legal/terms");
      final privacyResponse = await ApiService.client.get("/legal/privacy");

      setState(() {
        if (termsResponse.data['data'] != null) {
          termsVersion = termsResponse.data['data']['version'];
          termsContent = termsResponse.data['data']['content'];
        }
        if (privacyResponse.data['data'] != null) {
          privacyVersion = privacyResponse.data['data']['version'];
          privacyContent = privacyResponse.data['data']['content'];
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching legal documents: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          termsContent =
              "Failed to load Terms and Conditions. Please try again later.";
          privacyContent =
              "Failed to load Privacy Policy. Please try again later.";
        });
      }
    }
  }

  Future<void> register() async {
    setState(() {
      isRegistering = true;
      authErrorMessage = null;
    });

    try {
      final authRepository = AuthRepository();
      dynamic response;
      
      if (consentWidget.provider == 'google') {
        response = await authRepository.googleSignIn(
          idToken: consentWidget.googleIdToken!,
          termsAccepted: termsAccepted,
          privacyAcknowledged: privacyAcknowledged,
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
      } else if (consentWidget.provider == 'apple') {
        response = await authRepository.appleSignIn(
          identityToken: consentWidget.appleIdentityToken!,
          authorizationCode: consentWidget.appleAuthorizationCode!,
          platform: 'ios', 
          email: consentWidget.appleEmail,
          firstName: consentWidget.appleFirstName,
          lastName: consentWidget.appleLastName,
          termsAccepted: termsAccepted,
          privacyAcknowledged: privacyAcknowledged,
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
      } else {
        response = await authRepository.register(
          email: consentWidget.email!,
          password: consentWidget.password!,
          termsAccepted: termsAccepted,
          privacyAcknowledged: privacyAcknowledged,
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
      }

      if (response.success && response.user != null) {
        final sharedPrefs = await SharedPreferences.getInstance();
        sharedPrefs.setBool("isLoggedIn", true);

        final user = response.user!;
        sharedPrefs.setInt("userId", user.id);
        sharedPrefs.setString("profileStatus", user.profileStatus);
        sharedPrefs.setBool(
          "hasCompletedBasicDetails",
          user.hasCompletedBasicDetails,
        );
        sharedPrefs.setBool(
          "hasCompletedImageUpload",
          user.hasCompletedImageUpload,
        );
        sharedPrefs.setBool(
          "hasCompletedPartnerPreference",
          user.hasCompletedPartnerPreference,
        );
        if (user.name != null) {
          sharedPrefs.setString("name", user.name!);
        }
        sharedPrefs.setString("selfieStatus", user.selfieStatus ?? "NONE");

        if (!mounted) return;

        final onboardingStatus = OnboardingStatus(
          id: user.id,
          hasCompletedBasicDetails: user.hasCompletedBasicDetails,
          hasCompletedPartnerPreference: user.hasCompletedPartnerPreference,
          profileStatus: user.profileStatus,
          hasCompletedImageUpload: user.hasCompletedImageUpload,
          selfieStatus: user.selfieStatus,
        );

        context.read<AuthProvider>().loginSuccess(onboardingStatus);
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      String errorMessage = "Registration failed. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e);
      }
      if (mounted) {
        setState(() {
          authErrorMessage = errorMessage;
        });
        // Fallback snackbar for mobile if needed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  void showDocumentScreen(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullTextScreen(title: title, content: content),
      ),
    );
  }
}
