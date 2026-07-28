// ignore_for_file: unused_import

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/screens/password_screen/password_screen.dart';
import 'package:life_partner_again/services/auth_repository.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';

mixin OtpControllerState<T extends StatefulWidget> on State<T> {
  final AuthRepository authRepository = AuthRepository();
  final TextEditingController pinController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Timer? timer;
  int remainingSeconds = 60;
  bool get isResendEnabled => remainingSeconds == 0;

  String get email => (widget as dynamic).email;
  bool get isExistingUser => (widget as dynamic).isExistingUser;
  bool get isPasswordReset => (widget as dynamic).isPasswordReset;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    startTimer();
    pinController.addListener(_onPinChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageAssetProvider>().loadAssets('ONBOARDING_SCREEN');
    });
  }

  void _onPinChanged() {
    if (errorMessage != null) {
      setState(() {
        errorMessage = null;
      });
    }
  }

  void startTimer() {
    setState(() {
      remainingSeconds = 60;
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer?.cancel();
      }
    });
  }

  bool isResending = false;

  Future<void> verifyOtp(String pin) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await authRepository.verifyOtp(
        email: email,
        otp: pin,
        purpose: isPasswordReset ? "password_reset" : "auth",
      );

      debugPrint("OTP Verify Response: ${response.message}");

      if (response.success == true && mounted) {
        context.pushReplacement(
          AppRoutes.password,
          extra: PasswordArguments(
            email: email,
            isExistingUser: isExistingUser,
            isPasswordReset: isPasswordReset,
          ),
        );
      }
    } catch (e) {
      debugPrint("OTP Verify Error: $e");
      String errorMsg = "Invalid OTP. Please try again.";
      if (e is DioException) {
        errorMsg = getDioErrorMessage(e, fallback: errorMsg);
      }
      if (mounted) {
        setState(() {
          errorMessage = errorMsg;
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

  Future<void> resendOtp() async {
    if (!isResendEnabled || isResending) return;

    setState(() {
      isResending = true;
    });

    try {
      await authRepository.resendOtp(
        email: email,
        purpose: isPasswordReset ? "password_reset" : "auth",
      );
      startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP resent successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Resend OTP Error: $e");
      String errorMessage = "Failed to resend OTP";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e, fallback: errorMessage);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    pinController.removeListener(_onPinChanged);
    pinController.dispose();
    focusNode.dispose();
    timer?.cancel();
    super.dispose();
  }
}
