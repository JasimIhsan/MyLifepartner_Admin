import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/screens/otp_screen/widgets/otp_header.dart';
import 'package:mylifepartner/screens/password_screen/password_screen.dart';
import 'package:mylifepartner/services/auth_repository.dart';
import 'package:mylifepartner/shared/widgets/auth_layout.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';

import 'widgets/otp_form.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const OtpPage({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final AuthRepository _authRepository = AuthRepository();
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Timer? _timer;
  int _remainingSeconds = 60;
  bool get _isResendEnabled => _remainingSeconds == 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _verifyOtp(String pin) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _authRepository.verifyOtp(
        email: widget.email,
        otp: pin,
        purpose: widget.isPasswordReset ? "password_reset" : "auth",
      );

      debugPrint("OTP Verify Response: ${response.message}");

      if (response.success == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(
              email: widget.email,
              isExistingUser: widget.isExistingUser,
              isPasswordReset: widget.isPasswordReset,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("OTP Verify Error: $e");
      String errorMessage = "Invalid OTP. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e, fallback: errorMessage);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.black),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_isResendEnabled) return;

    try {
      await _authRepository.resendOtp(
        email: widget.email,
        purpose: widget.isPasswordReset ? "password_reset" : "auth",
      );
      _startTimer();

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
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      topImage: 'assets/images/landing_couple.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = MediaQuery.of(context).size.width > 900;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OtpHeader(
                email: widget.email,
                isWeb: isWeb,
                isPasswordReset: widget.isPasswordReset,
              ),
              const SizedBox(height: 32),
              OtpForm(
                formKey: formKey,
                pinController: pinController,
                focusNode: focusNode,
                isWeb: isWeb,
                isLoading: _isLoading,
                email: widget.email,
                onResend: _resendOtp,
                onVerify: _verifyOtp,
                timerValue: _remainingSeconds,
                isResendEnabled: _isResendEnabled,
              ),
            ],
          );
        },
      ),
    );
  }
}
