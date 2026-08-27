import 'package:life_partner_again/core/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/services/auth_repository.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_partner_again/screens/consent_privacy_screen/consent_privacy_screen.dart';
import 'package:provider/provider.dart';

mixin PasswordControllerState<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthRepository authRepository = AuthRepository();
  bool isLoading = false;
  bool obscureText = true;
  bool obscureConfirmText = true;
  String? authErrorMessage;

  String get email => (widget as dynamic).email;
  bool get isExistingUser => (widget as dynamic).isExistingUser;
  bool get isPasswordReset => (widget as dynamic).isPasswordReset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageAssetProvider>().loadAssets('ONBOARDING_SCREEN');
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      authErrorMessage = null;
    });

    try {
      if (isPasswordReset) {
        final response = await authRepository.forgotPassword(
          email: email,
          password: passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
          context.pushReplacement(
            AppRoutes.password,
            extra: PasswordArguments(email: email, isExistingUser: true),
          );
        }
        return;
      }

      if (!isExistingUser) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConsentPrivacyScreen(
                email: email,
                password: passwordController.text,
              ),
            ),
          );
        }
        return;
      }

      final response = await authRepository.login(
        email: email,
        password: passwordController.text,
      );

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
      debugPrint("Auth Error: $e");
      String errorMessage = "Authentication failed. Please try again.";
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

  Future<void> handleForgotPassword() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: Text(
            "Are you sure you want to reset the password for $email? We will send an OTP to your email address.",
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text(
                "Send OTP",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() {
      isLoading = true;
      authErrorMessage = null;
    });

    try {
      await authRepository.sendOtp(email: email, purpose: "password_reset");
      if (mounted) {
        context.push(
          AppRoutes.otp,
          extra: OtpArguments(
            email: email,
            isExistingUser: isExistingUser,
            isPasswordReset: true,
          ),
        );
      }
    } catch (e) {
      debugPrint("Send magic link error: $e");
      String errorMessage = "Failed to send reset link. Please try again.";
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
}
