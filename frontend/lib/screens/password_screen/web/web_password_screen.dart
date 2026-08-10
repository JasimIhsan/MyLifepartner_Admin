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
                "Secure Account Access",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Your safety is our top priority. Choose a strong, memorable password to shield your profile and match conversations from external threats.",
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
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isPasswordReset
                            ? "Reset Password"
                            : (widget.isExistingUser
                                  ? "Enter Password"
                                  : "Create Password"),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "For ${widget.email}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _buildPasswordField(),
                      if (widget.isExistingUser && !widget.isPasswordReset) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : handleForgotPassword,
                            child: const Text("Forgot Password?"),
                          ),
                        ),
                      ],
                      if (!widget.isExistingUser || widget.isPasswordReset) ...[
                        const SizedBox(height: 24),
                        _buildConfirmPasswordField(),
                      ],
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          onPressed: isLoading ? null : submit,
                          isLoading: isLoading,
                          text: widget.isPasswordReset
                              ? "Update Password"
                              : (widget.isExistingUser ? "Log In" : "Register"),
                          backgroundColor: Theme.of(context).primaryColor,
                          borderRadius: 12,
                          height: 54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
        color: Theme.of(context).textTheme.bodySmall?.color,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool obscure,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      hintText: hintText,
      hintStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Theme.of(context).textTheme.bodySmall?.color,
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
      borderRadius: BorderRadius.circular(12),
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
