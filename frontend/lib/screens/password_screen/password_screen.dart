import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/services/auth_repository.dart';
import 'package:mylifepartner/shared/widgets/auth_layout.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../home_screen/home_screen.dart';
import '../partner_preference/partner_preference_screen.dart';
import '../onboarding/onboarding_flow_screen.dart';
import '../profile_image_upload/profile_image_upload_screen.dart';
import '../selfie_verification/selfie_verification_screen.dart';
import '../otp_screen/otp_screen.dart';

class PasswordScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const PasswordScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isPasswordReset) {
        final response = await _authRepository.forgotPassword(
          email: widget.email,
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PasswordScreen(
                email: widget.email,
                isExistingUser: true,
              ),
            ),
          );
        }
        return;
      }

      final response = widget.isExistingUser
          ? await _authRepository.login(
              email: widget.email,
              password: _passwordController.text,
            )
          : await _authRepository.register(
              email: widget.email,
              password: _passwordController.text,
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

        if (!user.hasCompletedBasicDetails) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const OnboardingFlowScreen(),
            ),
            ModalRoute.withName('/'),
          );
        } else if (!user.hasCompletedPartnerPreference) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const PartnerPreferenceScreen(),
            ),
            ModalRoute.withName('/'),
          );
        } else {
          if (user.hasCompletedImageUpload == false) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileImageUploadScreen(),
              ),
              ModalRoute.withName('/'),
            );
          } else if (user.selfieStatus == null || user.selfieStatus == "NONE") {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const SelfieVerificationScreen(),
              ),
              ModalRoute.withName('/'),
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              ModalRoute.withName('/'),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      String errorMessage = "Authentication failed. Please try again.";
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

  Future<void> _handleForgotPassword() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Reset Password"),
          content: Text(
            "Are you sure you want to reset the password for ${widget.email}? We will send an OTP to your email address.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      _isLoading = true;
    });

    try {
      await _authRepository.sendOtp(
        email: widget.email,
        purpose: "password_reset",
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpPage(
              email: widget.email,
              isExistingUser: widget.isExistingUser,
              isPasswordReset: true,
            ),
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
    final bool isWeb = MediaQuery.of(context).size.width > 900;
    return AuthLayout(
      topImage: 'assets/images/login_young_couple.png',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isPasswordReset
                      ? "Reset Password"
                      : (widget.isExistingUser ? "Enter Password" : "Create Password"),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "For ${widget.email}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isWeb ? 16 : 14,
                      horizontal: isWeb ? 16 : 10,
                    ),
                    hintText: "Password",
                    hintStyle: const TextStyle(color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFA67C68)),
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
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                if (widget.isExistingUser && !widget.isPasswordReset) ...[
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      child: const Text("Forgot Password?"),
                    ),
                  ),
                ],
                if (!widget.isExistingUser || widget.isPasswordReset) ...[
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmText,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isWeb ? 16 : 14,
                        horizontal: isWeb ? 16 : 10,
                      ),
                      hintText: "Confirm Password",
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmText = !_obscureConfirmText;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFA67C68)),
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
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    onPressed: _isLoading ? null : _submit,
                    isLoading: _isLoading,
                    text: widget.isPasswordReset
                        ? "Update Password"
                        : (widget.isExistingUser ? "Log In" : "Register"),
                    backgroundColor: AppColors.primary,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
