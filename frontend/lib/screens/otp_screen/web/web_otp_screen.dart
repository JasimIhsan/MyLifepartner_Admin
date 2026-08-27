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
    final backgroundColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: OnboardingBackgroundImage(
                          alignment: Alignment.center,
                          loadingBackgroundColor: backgroundColor,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        left: 60,
                        child: _buildLogoHeader(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _buildFormContent(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Tablet layout
          return Stack(
            children: [
              Positioned.fill(
                child: OnboardingBackgroundImage(
                  alignment: Alignment.center,
                  loadingBackgroundColor: backgroundColor,
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: backgroundColor.withOpacity(0.95), // Minimalist solid overlay
                ),
              ),
              Positioned(
                top: 40,
                left: 40,
                child: _buildLogoHeader(darkText: true),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildFormContent(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoHeader({bool darkText = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/icons/app_logo_dark.png'
                : 'assets/icons/app_logo.png',
            height: 32,
            width: 32,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.favorite,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          "Life Partner Again",
          style: TextStyle(
            color: darkText
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Column(
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
    );
  }
}
