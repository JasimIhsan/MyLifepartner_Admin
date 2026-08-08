import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/password_controller.dart';

class MobilePasswordScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const MobilePasswordScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  State<MobilePasswordScreen> createState() => _MobilePasswordScreenState();
}

class _MobilePasswordScreenState extends State<MobilePasswordScreen>
    with PasswordControllerState {
  String get _message {
    if (widget.isPasswordReset) {
      return "Please enter a new password for your account.";
    }
    if (widget.isExistingUser) {
      return "Enter your password to access your account.";
    }
    return "Set up a password to secure your new account.";
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final backgroundColor = Theme.of(context).colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor =
        Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    final secondaryTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

    final inputFillColor =
        isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92);
    final inputBorderColor =
        isDark
            ? AppColors.darkBorderColor
            : AppColors.borderColor.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.65,
            child: Consumer<ImageAssetProvider>(
              builder: (context, provider, _) {
                final asset = provider.getFeaturedAsset('ONBOARDING_SCREEN');
                if (asset != null) {
                  return CachedNetworkImage(
                    imageUrl: asset.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  );
                }
                return Image.asset(
                  'assets/images/landing_couple.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                );
              },
            ),
          ),

          // Seamless Gradient Fade to Background Color (no hard cutoff)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.72,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.80, 1.0],
                  colors: [
                    backgroundColor.withValues(alpha: 0.0),
                    backgroundColor.withValues(alpha: 0.3),
                    backgroundColor.withValues(alpha: 0.9),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content Area with Keyboard Support
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back Button
                            if (context.canPop())
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () => context.pop(),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 48),

                            const Spacer(),
                            const SizedBox(height: 16),

                            // Form Container
                            Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.isPasswordReset
                                        ? "Reset Password"
                                        : (widget.isExistingUser
                                            ? "Enter Password"
                                            : "Create Password"),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: primaryTextColor,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _message,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text.rich(
                                    TextSpan(
                                      text: "For ",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: secondaryTextColor,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: widget.email,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: primaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Password Input Field
                                  TextFormField(
                                    controller: passwordController,
                                    obscureText: obscureText,
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontSize: 17,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: inputFillColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 20,
                                          ),
                                      hintText: "Password",
                                      hintStyle: TextStyle(
                                        color:
                                            isDark
                                                ? AppColors.darkTextLight
                                                : AppColors.textLight,
                                        fontSize: 15,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscureText
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color:
                                              isDark
                                                  ? AppColors.darkTextLight
                                                  : AppColors.textLight,
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            obscureText = !obscureText;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: inputBorderColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: inputBorderColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color: Theme.of(context).primaryColor,
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (value.length < 8) {
                                        return 'Password must be at least 8 characters';
                                      }
                                      if (!value.contains(RegExp(r'[A-Z]'))) {
                                        return 'Password must contain at least one uppercase letter';
                                      }
                                      if (!value.contains(RegExp(r'[a-z]'))) {
                                        return 'Password must contain at least one lowercase letter';
                                      }
                                      if (!value.contains(RegExp(r'[0-9]'))) {
                                        return 'Password must contain at least one number';
                                      }
                                      if (!value.contains(
                                        RegExp(r'[!@#\$%^&*(),.?":{}|<>]'),
                                      )) {
                                        return 'Password must contain at least one special character';
                                      }
                                      return null;
                                    },
                                  ),

                                  // Forgot password link or Confirm password field
                                  if (widget.isExistingUser &&
                                      !widget.isPasswordReset) ...[
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed:
                                            isLoading
                                                ? null
                                                : handleForgotPassword,
                                        child: Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: confirmPasswordController,
                                      obscureText: obscureConfirmText,
                                      style: TextStyle(
                                        color: primaryTextColor,
                                        fontSize: 17,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: inputFillColor,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 18,
                                              horizontal: 20,
                                            ),
                                        hintText: "Confirm Password",
                                        hintStyle: TextStyle(
                                          color:
                                              isDark
                                                  ? AppColors.darkTextLight
                                                  : AppColors.textLight,
                                          fontSize: 15,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            obscureConfirmText
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color:
                                                isDark
                                                    ? AppColors.darkTextLight
                                                    : AppColors.textLight,
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              obscureConfirmText =
                                                  !obscureConfirmText;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide(
                                            color: inputBorderColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide(
                                            color: inputBorderColor,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(context).primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please confirm your password';
                                        }
                                        if (value != passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 24),

                                  // Submit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                        disabledBackgroundColor:
                                            Theme.of(context).dividerColor,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child:
                                          isLoading
                                              ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.onPrimary,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : Text(
                                                widget.isPasswordReset
                                                    ? "Update Password"
                                                    : (widget.isExistingUser
                                                        ? "Log In"
                                                        : "Register"),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
