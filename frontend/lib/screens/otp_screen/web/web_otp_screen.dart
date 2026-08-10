import 'package:flutter/material.dart';
import 'package:life_partner_again/widgets/onboarding_background_image.dart';

import '../widgets/otp_controller.dart';
import '../widgets/otp_form.dart';
import '../widgets/otp_header.dart';

class WebOtpScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const WebOtpScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  State<WebOtpScreen> createState() => _WebOtpScreenState();
}

class _WebOtpScreenState extends State<WebOtpScreen> with OtpControllerState {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          Expanded(flex: 1, child: _buildBrandingPanel()),
          Expanded(flex: 1, child: _buildFormPanel()),
        ],
      ),
    );
  }

  Widget _buildBrandingPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingBackgroundImage(alignment: Alignment.center),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.72),
                Theme.of(context).primaryColor.withValues(alpha: 0.58),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogoRow(),
              const SizedBox(height: 60),
              const Text(
                "Secure Authentication",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "We have sent a verification code to your email. Enter the code to verify your identity and access your account safely.",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/icons/app_logo_dark.png'
                : 'assets/icons/app_logo.png',
            height: 48,
            width: 48,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.favorite,
              color: Theme.of(context).primaryColor,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          "Life Partner Again",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            elevation: 4,
            shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OtpHeader(
                      email: widget.email,
                      isWeb: true,
                      isPasswordReset: widget.isPasswordReset,
                    ),
                    const SizedBox(height: 32),
                    OtpForm(
                      formKey: formKey,
                      pinController: pinController,
                      focusNode: focusNode,
                      isWeb: true,
                      isLoading: isLoading,
                      isResending: isResending,
                      email: widget.email,
                      onResend: resendOtp,
                      onVerify: verifyOtp,
                      timerValue: remainingSeconds,
                      isResendEnabled: isResendEnabled,
                      errorMessage: errorMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
