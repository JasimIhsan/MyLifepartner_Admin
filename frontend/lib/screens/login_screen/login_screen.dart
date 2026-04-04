import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/services/auth_repository.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';

import '../../shared/widgets/auth_layout.dart';
import '../../shared/widgets/custom_button.dart';
import '../otp_screen/otp_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initiateAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text.trim();
      final response = await _authRepository.initiateAuth(email: email);

      debugPrint("Initiate Auth Response: ${response.message}");
      if (response.success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtpPage(email: email, isExistingUser: response.exists),
          ),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      topImage: 'assets/images/landing_couple.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Check screen width for responsive text/style, matching AuthLayout breakpoint logic partially
          // AuthLayout uses 900 breakpoint for split screen.
          final bool isWeb = MediaQuery.of(context).size.width > 900;
          return _buildFormContent(isWeb);
        },
      ),
    );
  }

  Widget _buildFormContent(bool isWeb) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your email",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBackground,
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
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
              );
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          Text(
            "We’ll send a verification code to your email.",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: _isLoading ? null : _initiateAuth,
              isLoading: _isLoading,
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
    return Text.rich(
      TextSpan(
        text: "By continue, you agree to our ",
        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
        children: [
          TextSpan(
            text: "Terms of Service",
            style: GoogleFonts.poppins(
              decoration: TextDecoration.underline,
              color: AppColors.textLight,
            ),
          ),
          const TextSpan(text: " and "),
          TextSpan(
            text: "Privacy Policy",
            style: GoogleFonts.poppins(
              decoration: TextDecoration.underline,
              color: AppColors.textLight,
            ),
          ),
          const TextSpan(text: "."),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
