import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/services/auth_repository.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:provider/provider.dart';

mixin LoginControllerState<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final AuthRepository authRepository = AuthRepository();
  bool isLoading = false;

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
