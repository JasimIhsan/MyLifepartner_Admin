import 'package:flutter/material.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:life_partner_again/widgets/onboarding_background_image.dart';

import '../widgets/password_controller.dart';

class WebPasswordScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const WebPasswordScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  State<WebPasswordScreen> createState() => _WebPasswordScreenState();
}

class _WebPasswordScreenState extends State<WebPasswordScreen>
    with PasswordControllerState {
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
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isPasswordReset
                ? "Reset Password"
                : (widget.isExistingUser ? "Enter Password" : "Create Password"),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "For ${widget.email}",
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 40),
          
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

          _buildPasswordField(),
          if (widget.isExistingUser && !widget.isPasswordReset) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : handleForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
          if (!widget.isExistingUser || widget.isPasswordReset) ...[
            const SizedBox(height: 24),
            _buildConfirmPasswordField(),
          ],
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : submit,
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
                  : Text(
                      widget.isPasswordReset
                          ? "Update Password"
                          : (widget.isExistingUser ? "Log In" : "Register"),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Password"),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          obscureText: obscureText,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
          decoration: _inputDecoration(
            hintText: "Enter password",
            obscure: obscureText,
            onToggleVisibility: () {
              setState(() {
                obscureText = !obscureText;
              });
            },
          ),
          validator: _validatePassword,
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Confirm Password"),
        const SizedBox(height: 8),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: obscureConfirmText,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 16,
          ),
          decoration: _inputDecoration(
            hintText: "Confirm password",
            obscure: obscureConfirmText,
            onToggleVisibility: () {
              setState(() {
                obscureConfirmText = !obscureConfirmText;
              });
            },
          ),
          validator: _validateConfirmPassword,
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      errorMaxLines: 3,
      filled: true,
      fillColor: Theme.of(context).canvasColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      hintText: hintText,
      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).textTheme.bodySmall?.color,
          size: 20,
        ),
        onPressed: onToggleVisibility,
      ),
      border: _inputBorder(Theme.of(context).dividerColor),
      enabledBorder: _inputBorder(Theme.of(context).dividerColor),
      focusedBorder: _inputBorder(Theme.of(context).primaryColor, width: 1.5),
      errorBorder: _inputBorder(Theme.of(context).colorScheme.error),
      focusedErrorBorder: _inputBorder(Theme.of(context).colorScheme.error),
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  String? _validatePassword(String? value) {
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
    if (!value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}
