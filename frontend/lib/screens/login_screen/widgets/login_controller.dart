import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/services/apple_auth_service.dart';
import 'package:life_partner_again/services/auth_repository.dart';
import 'package:life_partner_again/services/google_auth_service.dart';
import 'package:life_partner_again/screens/consent_privacy_screen/consent_privacy_screen.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin LoginControllerState<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final AuthRepository authRepository = AuthRepository();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool isAppleLoading = false;
  String? authErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageAssetProvider>().loadAssets('ONBOARDING_SCREEN');
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> initiateAuth() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      authErrorMessage = null;
    });

    try {
      final email = emailController.text.trim().toLowerCase();
      final response = await authRepository.initiateAuth(email: email);

      debugPrint("Initiate Auth Response: ${response.message}");
      if (response.success && mounted) {
        context.push(
          AppRoutes.otp,
          extra: OtpArguments(email: email, isExistingUser: response.exists),
        );
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      String errorMessage = "Failed to start authentication. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e);
      }
      if (mounted) {
        setState(() {
          authErrorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> processGoogleIdToken(
    String idToken, {
    bool skipLoadingCheck = false,
  }) async {
    if (!skipLoadingCheck && isGoogleLoading) return;

    if (!isGoogleLoading) {
      setState(() {
        isGoogleLoading = true;
        authErrorMessage = null;
      });
    }

    try {
      debugPrint(
        "Starting backend Google Sign-In with idToken length: ${idToken.length}",
      );
      final response = await authRepository.googleSignIn(idToken: idToken);
      debugPrint(
        "Backend Google Sign-In Response: success=${response.success}",
      );

      if (response.success && response.action == 'REQUIRE_CONSENT') {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConsentPrivacyScreen(
              provider: 'google',
              googleIdToken: idToken,
              email: response.email,
              firstName: response.firstName,
              lastName: response.lastName,
            ),
          ),
        );
        return;
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
        } else {
          sharedPrefs.remove("name");
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
      debugPrint("Google Auth Backend Error: $e");
      String errorMessage = "Failed to sign in with Google. Please try again.";
      if (e is DioException) {
        debugPrint(
          "DioException Status Code: ${e.response?.statusCode}, Error: ${e.response?.data}",
        );
        errorMessage = getDioErrorMessage(e);
      }
      if (mounted) {
        setState(() {
          authErrorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> initiateGoogleAuth() async {
    if (isGoogleLoading) return;

    setState(() {
      isGoogleLoading = true;
      authErrorMessage = null;
    });

    try {
      final String? idToken = await GoogleAuthService.instance.authenticate();
      if (idToken == null) {
        return;
      }

      await processGoogleIdToken(idToken, skipLoadingCheck: true);
    } on GoogleAuthCancelledException {
      debugPrint("Google Sign-In was cancelled by user.");
    } catch (e) {
      debugPrint("Google Auth Error: $e");
      String errorMessage = "Failed to sign in with Google. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e);
      } else if (e is GoogleAuthException) {
        errorMessage = e.message;
      }
      if (mounted) {
        setState(() {
          authErrorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> initiateAppleAuth() async {
    if (isAppleLoading) return;

    setState(() {
      isAppleLoading = true;
      authErrorMessage = null;
    });

    try {
      final result = await AppleAuthService.instance.authenticate();
      if (result == null) {
        return;
      }

      debugPrint("Starting backend Apple Sign-In");
      final response = await authRepository.appleSignIn(
        identityToken: result.identityToken,
        authorizationCode: result.authorizationCode,
        platform: result.platform,
        email: result.email,
        firstName: result.firstName,
        lastName: result.lastName,
        nonce: result.rawNonce,
      );

      debugPrint("Backend Apple Sign-In Response: success=${response.success}");

      if (response.success && response.action == 'REQUIRE_CONSENT') {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConsentPrivacyScreen(
              provider: 'apple',
              appleIdentityToken: result.identityToken,
              appleAuthorizationCode: result.authorizationCode,
              appleEmail: result.email,
              appleFirstName: result.firstName,
              appleLastName: result.lastName,
              email: response.email,
              firstName: response.firstName,
              lastName: response.lastName,
            ),
          ),
        );
        return;
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
        } else {
          sharedPrefs.remove("name");
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
    } on AppleAuthCancelledException {
      debugPrint("Apple Sign-In was cancelled by user.");
    } catch (e) {
      debugPrint("Apple Auth Error: $e");
      String errorMessage = "Failed to sign in with Apple. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e);
      } else if (e is AppleAuthException) {
        errorMessage = e.message;
      }
      if (mounted) {
        setState(() {
          authErrorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isAppleLoading = false;
        });
      }
    }
  }

  Future<void> handleBackPress() async {
    if (!mounted) return;

    await CustomBottomSheet.show(
      context: context,
      type: BottomSheetType.confirmation,
      title: 'Exit App',
      message: 'Are you sure you want to exit the app?',
      primaryButtonText: 'Exit',
      onPrimaryPressed: () {
        SystemNavigator.pop();
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        context.pop();
      },
      imagePath: 'assets/images/illustrations/exit.png',
    );
  }
}
