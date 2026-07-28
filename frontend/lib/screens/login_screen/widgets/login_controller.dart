import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/services/auth_repository.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> initiateGoogleAuth() async {
    setState(() {
      isGoogleLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
        serverClientId: Env.googleServerClientId,
      );
      
      // Force sign out to show the account picker every time
      await googleSignIn.signOut();

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        if (auth.idToken != null) {
          final response = await authRepository.googleSignIn(
            idToken: auth.idToken!,
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
        } else {
          throw Exception("Could not retrieve ID token from Google");
        }
      }
    } catch (e) {
      debugPrint("Google Auth Error: $e");
      String errorMessage = "Failed to sign in with Google. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGoogleLoading = false;
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
