import 'package:flutter/material.dart';
import '../widgets/consent_controller.dart';

class MobileConsentScreen extends StatefulWidget {
  const MobileConsentScreen({super.key});

  @override
  State<MobileConsentScreen> createState() => _MobileConsentScreenState();
}

class _MobileConsentScreenState extends State<MobileConsentScreen>
    with ConsentControllerState {
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
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.05)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.8,
                      ),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        title: const Text("Legal & Privacy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.security_rounded,
                                  size: 48,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Your Privacy Matters",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Please review and accept our Terms and Privacy Policy to create your account. We prioritize your safety and data protection.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 40),

                              // Terms Card
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
                                onReadMore: () => showDocumentScreen(
                                  "Terms and Conditions",
                                  termsContent,
                                ),
                                linkText: "Read Full Terms",
                              ),

                              const SizedBox(height: 16),

                              // Privacy Card
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
                                onReadMore: () => showDocumentScreen(
                                  "Privacy Policy",
                                  privacyContent,
                                ),
                                linkText: "Read Privacy Policy",
                              ),

                              const Spacer(),
                              const SizedBox(height: 32),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      (termsAccepted &&
                                          privacyAcknowledged &&
                                          !isRegistering)
                                      ? register
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    disabledBackgroundColor: theme.dividerColor,
                                    elevation:
                                        (termsAccepted && privacyAcknowledged)
                                        ? 4
                                        : 0,
                                    shadowColor: primaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isRegistering
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          "Create Account",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
