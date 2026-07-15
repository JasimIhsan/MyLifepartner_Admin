import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/auth_layout.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import '../widgets/login_controller.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen>
    with LoginControllerState {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackPress();
      },
      child: AuthLayout(
        topImage: 'assets/images/landing_couple.png',
        dynamicSection: 'ONBOARDING_SCREEN',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = MediaQuery.of(context).size.width > 900;
            return _buildFormContent(isWeb);
          },
        ),
      ),
    );
  }

  Widget _buildFormContent(bool isWeb) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Enter your email",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.textWhite,
              contentPadding: EdgeInsets.symmetric(
                vertical: isWeb ? 16 : 14,
                horizontal: isWeb ? 16 : 10,
              ),
              hintText: "Enter your email address",
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              final emailRegex = RegExp(
                r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$",
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          const Text(
            "We’ll send a verification code to your email.",
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: isLoading ? null : initiateAuth,
              isLoading: isLoading,
              text: "Continue",
              backgroundColor: AppColors.primary,
              borderRadius: 12,
              height: 52,
            ),
          ),
          const SizedBox(height: 24),
          Center(child: _buildFooterText()),
        ],
      ),
    );
  }

  Widget _buildFooterText() {
    return const Text.rich(
      TextSpan(
        text: "By continue, you agree to our ",
        style: TextStyle(fontSize: 12, color: AppColors.textLight),
        children: [
          TextSpan(
            text: "Terms of Service",
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: AppColors.textLight,
            ),
          ),
          TextSpan(text: " and "),
          TextSpan(
            text: "Privacy Policy",
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: AppColors.textLight,
            ),
          ),
          TextSpan(text: "."),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
