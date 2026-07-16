import 'package:flutter/material.dart';
import 'package:life_partner_again/widgets/auth_layout.dart';
import '../widgets/otp_controller.dart';
import '../widgets/otp_form.dart';
import '../widgets/otp_header.dart';

class MobileOtpScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const MobileOtpScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  State<MobileOtpScreen> createState() => _MobileOtpScreenState();
}

class _MobileOtpScreenState extends State<MobileOtpScreen>
    with OtpControllerState {
  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      topImage: 'assets/images/landing_couple.png',
      dynamicSection: 'ONBOARDING_SCREEN',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OtpHeader(
            email: widget.email,
            isWeb: false,
            isPasswordReset: widget.isPasswordReset,
          ),
          const SizedBox(height: 32),
          OtpForm(
            formKey: formKey,
            pinController: pinController,
            focusNode: focusNode,
            isWeb: false,
            isLoading: isLoading,
            isResending: isResending,
            email: widget.email,
            onResend: resendOtp,
            onVerify: verifyOtp,
            timerValue: remainingSeconds,
            isResendEnabled: isResendEnabled,
          ),
        ],
      ),
    );
  }
}
