import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;
import 'package:life_partner_again/services/google_auth_service.dart';
import 'package:life_partner_again/widgets/onboarding_background_image.dart';

import '../widgets/login_controller.dart';

class WebLoginScreen extends StatefulWidget {
  const WebLoginScreen({super.key});

  @override
  State<WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen>
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 60),
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

          // Tablet / smaller screen layout
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Life\nPartner\nAgain.",
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            height: 1.1,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "A premium space for emotionally mature relationships. Join a community built on respect and depth.",
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 48),

        if (authErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Theme.of(context).colorScheme.error, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      authErrorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        Form(
          key: formKey,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showEmailForm ? _buildEmailForm() : _buildActionList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            _buildEditorialButton(
              icon: isGoogleLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : SvgPicture.string(_googleSvg, width: 24, height: 24),
              label: isGoogleLoading
                  ? "Continuing..."
                  : "Continue with Google",
              onPressed: isGoogleLoading ? null : initiateGoogleAuth, // Kept for mobile/non-web cases if ever compiled differently, but on web it's ignored due to overlay
              isPrimary: true,
            ),
            if (!isGoogleLoading)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.01,
                  child: web_only.renderButton(
                    configuration: web_only.GSIButtonConfiguration(
                      minimumWidth: 400,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _buildEditorialButton(
          icon: isAppleLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.apple,
                  color: Theme.of(context).iconTheme.color,
                  size: 26,
                ),
          label: isAppleLoading
              ? "Continuing..."
              : "Continue with Apple",
          onPressed: isAppleLoading ? null : initiateAppleAuth,
          isPrimary: true,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            setState(() {
              _showEmailForm = true;
              authErrorMessage = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
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
                const SizedBox(width: 16),
                Text(
                  "Continue with Email",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showEmailForm = false;
              authErrorMessage = null;
            });
          },
          child: Row(
            children: [
              Icon(Icons.arrow_back,
                  size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(
                "Back to options",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Enter your email",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).canvasColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
            hintText: "name@example.com",
            hintStyle: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1,
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : initiateAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              disabledBackgroundColor: Theme.of(context).dividerColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  }) {
    final bool disabled = onPressed == null;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Opacity(
                  opacity: disabled ? 0.5 : 1.0,
                  child: icon,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
