import 'package:flutter/material.dart';
import 'package:life_partner_again/widgets/onboarding_background_image.dart';

import '../widgets/consent_controller.dart';

class WebConsentScreen extends StatefulWidget {
  const WebConsentScreen({super.key});

  @override
  State<WebConsentScreen> createState() => _WebConsentScreenState();
}

class _WebConsentScreenState extends State<WebConsentScreen>
    with ConsentControllerState {
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
                        child: Container(color: Colors.black.withOpacity(0.3)),
                      ),
                      Positioned(top: 60, left: 60, child: _buildLogoHeader()),
                    ],
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 60,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
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
                  color: backgroundColor.withOpacity(
                    0.95,
                  ), // Minimalist solid overlay
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
                    constraints: const BoxConstraints(maxWidth: 480),
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
    final theme = Theme.of(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryColor),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security_rounded,
            size: 40,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Legal & Privacy",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: theme.textTheme.bodyLarge?.color,
            height: 1.1,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Please review and accept our Terms and Privacy Policy to create your account. We prioritize your safety and data protection.",
          style: TextStyle(
            fontSize: 16,
            color: theme.textTheme.bodyMedium?.color,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),

        if (authErrorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.error, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      authErrorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        _buildConsentCard(
          title: "Terms & Conditions",
          description:
              "I agree to the Terms and Conditions of Life Partner Again.",
          value: termsAccepted,
          onChanged: (val) {
            setState(() {
              termsAccepted = val ?? false;
            });
          },
          onReadMore: () =>
              showDocumentScreen("Terms and Conditions", termsContent),
          linkText: "Read Full Terms",
        ),
        const SizedBox(height: 20),
        _buildConsentCard(
          title: "Privacy Policy",
          description:
              "I have read and consent to the processing of my data as described in the Privacy Policy.",
          value: privacyAcknowledged,
          onChanged: (val) {
            setState(() {
              privacyAcknowledged = val ?? false;
            });
          },
          onReadMore: () =>
              showDocumentScreen("Privacy Policy", privacyContent),
          linkText: "Read Privacy Policy",
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (termsAccepted && privacyAcknowledged && !isRegistering)
                ? register
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.dividerColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: isRegistering
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentCard({
    required String title,
    required String description,
    required bool value,
    required Function(bool?) onChanged,
    required VoidCallback onReadMore,
    required String linkText,
  }) {
    final theme = Theme.of(context);
    final isSelected = value;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: theme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onReadMore,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          linkText,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: theme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
