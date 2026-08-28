import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/services/google_auth_service.dart';
import 'package:life_partner_again/widgets/onboarding_background_image.dart';

import '../widgets/google_web_button.dart';
import '../widgets/login_controller.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen>
    with LoginControllerState {
  bool _showEmailForm = false;

  final String _googleSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>''';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initWebGoogleSignIn();
    }
  }

  Future<void> _initWebGoogleSignIn() async {
    await GoogleAuthService.instance.ensureInitialized();
    GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          final String? idToken = event.user.authentication.idToken;
          if (idToken != null && idToken.isNotEmpty) {
            processGoogleIdToken(idToken);
          }
        }
      },
      onError: (error) {
        debugPrint("Google Web Sign-In event error: $error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final backgroundColor = Theme.of(
      context,
    ).colorScheme.surface; // Light theme background

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_showEmailForm) {
          setState(() {
            _showEmailForm = false;
          });
        } else {
          handleBackPress();
        }
      },
      child: Scaffold(
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
              child: const OnboardingBackgroundImage(),
            ),

            // Gradient Fade to Background Color
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.70,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 0.8, 1.0],
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

            // Main Content Area
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Optional Back Button
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
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.arrow_back_ios_new,
                                          color: Theme.of(
                                            context,
                                          ).iconTheme.color,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          if (_showEmailForm) {
                                            setState(() {
                                              _showEmailForm = false;
                                            });
                                          } else {
                                            context.pop();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 48),

                            const Spacer(),

                            // Editorial Headline
                            Text(
                              "Life\nPartner\nAgain.",
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                                height: 1.0,
                                letterSpacing: -2.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "A premium space for emotionally mature relationships.",
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    AppColors.textSecondary,
                                height: 1.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 48),

                            if (authErrorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        authErrorMessage!,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Actions Container
                            Form(
                              key: formKey,
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutQuint,
                                child: _showEmailForm
                                    ? _buildEmailForm()
                                    : _buildActionList(),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Terms
                            Center(
                              child: Text.rich(
                                TextSpan(
                                  text: "By continuing, you agree to our ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color ??
                                        AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Terms",
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            AppColors.textPrimary,
                                      ),
                                    ),
                                    const TextSpan(text: " and "),
                                    TextSpan(
                                      text: "Privacy",
                                      style: TextStyle(
                                        color:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            AppColors.textPrimary,
                                      ),
                                    ),
                                    const TextSpan(text: "."),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary (Google) - Enabled
        Stack(
          children: [
            _buildEditorialButton(
              icon: isGoogleLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : SvgPicture.string(_googleSvg, width: 22, height: 22),
              label: isGoogleLoading
                  ? "Continuing..."
                  : "Continue with Google",
              onPressed: isGoogleLoading ? null : initiateGoogleAuth,
              isPrimary: true,
            ),
            if (kIsWeb && !isGoogleLoading)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.01,
                  child: getGoogleWebButton(
                    minimumWidth: 400,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Tertiary (Apple) - Active
        _buildEditorialButton(
          icon: isAppleLoading
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.apple,
                  color: Theme.of(context).iconTheme.color,
                  size: 26,
                ),
          label: isAppleLoading
              ? "Continuing with Apple..."
              : "Continue with Apple",
          onPressed: isAppleLoading ? null : initiateAppleAuth,
          isPrimary: true,
        ),

        const SizedBox(height: 16),

        // Secondary (Email) - Active
        GestureDetector(
          onTap: () {
            setState(() {
              _showEmailForm = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  color: Theme.of(context).iconTheme.color,
                  size: 22,
                ),
                SizedBox(width: 16),
                Text(
                  "Continue with Email",
                  style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.unselectedIcon,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Enter your email",
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          enabled: !isLoading,
          keyboardType: TextInputType.text,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
            fontSize: 18,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 20,
            ),
            hintText: "name@example.com",
            hintStyle: TextStyle(
              color:
                  Theme.of(context).textTheme.bodySmall?.color ??
                  AppColors.textLight,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
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
              return 'Invalid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isLoading ? null : initiateAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            disabledBackgroundColor: Theme.of(context).dividerColor,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ],
    );
  }

  Widget _buildEditorialButton({
    required Widget icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isMuted = false,
    String? badgeText,
  }) {
    final bool disabled = onPressed == null;

    final bgColor = isPrimary
        ? Theme.of(context).colorScheme.surface
        : Colors.transparent;

    final borderColor = isPrimary
        ? Theme.of(context).dividerColor
        : (isMuted ? Colors.transparent : Theme.of(context).dividerColor);

    final textColor = isMuted
        ? Theme.of(context).textTheme.bodyMedium?.color ??
              AppColors.textSecondary
        : Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15), // Preserved from user edits
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10), // Preserved from user edits
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Opacity(
                  opacity: isMuted ? 0.4 : (disabled ? 0.6 : 1.0),
                  child: icon,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: disabled ? 0.4 : 1.0),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
