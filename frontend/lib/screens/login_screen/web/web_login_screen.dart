import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/services/google_auth_service.dart';
import 'package:provider/provider.dart';

import '../widgets/login_controller.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen>
    with LoginControllerState {
  bool _showEmailForm = false;

  @override
  void initState() {
    super.initState();
    _initWebGoogleSignIn();
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
    final backgroundColor = const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Left side - 60% Image Area
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Consumer<ImageAssetProvider>(
                    builder: (context, provider, _) {
                      final asset = provider.getFeaturedAsset(
                        'ONBOARDING_SCREEN',
                      );
                      if (asset != null) {
                        return CachedNetworkImage(
                          imageUrl: asset.imageUrl,
                          fit: BoxFit.cover,
                        );
                      }
                      return Image.asset(
                        'assets/images/landing_couple.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                // Gradient overlay to make text legible
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 60,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/icons/app_logo.png',
                          height: 32,
                          width: 32,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.favorite,
                                color: AppColors.primary,
                                size: 24,
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "Life Partner Again",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right side - 40% Editorial Form Area
          Expanded(
            flex: 4,
            child: Container(
              color: backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Life\nPartner\nAgain.",
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          height: 1.0,
                          letterSpacing: -2.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "A premium space for emotionally mature relationships. Join a community built on respect and depth.",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 60),

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

                      const Spacer(),

                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: "By continuing, you agree to our ",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            children: [
                              const TextSpan(
                                text: "Terms",
                                style: TextStyle(
                                  color: Colors.black87,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: " and "),
                              const TextSpan(
                                text: "Privacy",
                                style: TextStyle(
                                  color: Colors.black87,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: "."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary (Google) - GIS Web Button / Loading
        if (isGoogleLoading)
          _buildEditorialButton(
            icon: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            label: "Continuing with Google...",
            onPressed: null,
            isPrimary: true,
          )
        else
          SizedBox(
            height: 64,
            child: web.renderButton(
              configuration: web.GSIButtonConfiguration(
                theme: web.GSIButtonTheme.outline,
                size: web.GSIButtonSize.large,
                text: web.GSIButtonText.continueWith,
                shape: web.GSIButtonShape.rectangular,
                logoAlignment: web.GSIButtonLogoAlignment.left,
              ),
            ),
          ),
        const SizedBox(height: 16),


        // Tertiary (Apple) - Disabled (Made primary-styled by user)
        _buildEditorialButton(
          icon: const Icon(Icons.apple, color: Colors.black87, size: 28),
          label: "Continue with Apple",
          onPressed: null,
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.mail_outline, color: Colors.black87, size: 24),
                SizedBox(width: 16),
                Text(
                  "Continue with Email",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.black45, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () {
            setState(() {
              _showEmailForm = false;
            });
          },
        ),
        const SizedBox(height: 16),
        const Text(
          "Enter your email",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.black87, fontSize: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 20,
            ),
            hintText: "name@example.com",
            hintStyle: const TextStyle(color: Colors.black38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.black87, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
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
              return 'Invalid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : initiateAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Continue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
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

    final bgColor = isPrimary ? Colors.white : Colors.transparent;

    final borderColor = isPrimary
        ? Colors.grey.shade300
        : (isMuted ? Colors.transparent : Colors.grey.shade300);

    final textColor = isMuted ? Colors.black54 : Colors.black87;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: disabled ? 0.4 : 1.0),
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
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
