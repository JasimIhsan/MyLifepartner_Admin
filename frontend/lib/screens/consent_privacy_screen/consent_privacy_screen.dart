import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:life_partner_again/models/onboarding_status.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/services/auth_repository.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentPrivacyScreen extends StatefulWidget {
  final String? email;
  final String? password;
  final String? provider;
  final String? googleIdToken;
  final String? appleIdentityToken;
  final String? appleAuthorizationCode;
  final String? appleEmail;
  final String? appleFirstName;
  final String? appleLastName;
  final String? firstName;
  final String? lastName;

  const ConsentPrivacyScreen({
    super.key,
    this.email,
    this.password,
    this.provider,
    this.googleIdToken,
    this.appleIdentityToken,
    this.appleAuthorizationCode,
    this.appleEmail,
    this.appleFirstName,
    this.appleLastName,
    this.firstName,
    this.lastName,
  });

  @override
  State<ConsentPrivacyScreen> createState() => _ConsentPrivacyScreenState();
}

class _ConsentPrivacyScreenState extends State<ConsentPrivacyScreen> {
  bool isLoading = true;
  bool isRegistering = false;

  bool termsAccepted = false;
  bool privacyAcknowledged = false;

  String? termsVersion;
  String? privacyVersion;
  String termsContent = "Loading terms...";
  String privacyContent = "Loading privacy policy...";

  @override
  void initState() {
    super.initState();
    _fetchLegalDocuments();
  }

  Future<void> _fetchLegalDocuments() async {
    try {
      final termsResponse = await ApiService.client.get("/legal/terms");
      final privacyResponse = await ApiService.client.get("/legal/privacy");

      setState(() {
        if (termsResponse.data['data'] != null) {
          termsVersion = termsResponse.data['data']['version'];
          termsContent = termsResponse.data['data']['content'];
        }
        if (privacyResponse.data['data'] != null) {
          privacyVersion = privacyResponse.data['data']['version'];
          privacyContent = privacyResponse.data['data']['content'];
        }
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching legal documents: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          termsContent =
              "Failed to load Terms and Conditions. Please try again later.";
          privacyContent =
              "Failed to load Privacy Policy. Please try again later.";
        });
      }
    }
  }

  Future<void> _register() async {
    setState(() {
      isRegistering = true;
    });

    try {
      final authRepository = AuthRepository();
      dynamic response;
      
      if (widget.provider == 'google') {
        response = await authRepository.googleSignIn(
          idToken: widget.googleIdToken!,
          termsAccepted: termsAccepted,
          privacyAcknowledged: privacyAcknowledged,
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
      } else if (widget.provider == 'apple') {
        response = await authRepository.appleSignIn(
          identityToken: widget.appleIdentityToken!,
          authorizationCode: widget.appleAuthorizationCode!,
          platform: 'ios', // or extract from where it's known, but apple is usually ios
          email: widget.appleEmail,
          firstName: widget.appleFirstName,
          lastName: widget.appleLastName,
          termsAccepted: termsAccepted,
          privacyAcknowledged: privacyAcknowledged,
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
      } else {
        response = await authRepository.register(
          email: widget.email!,
          password: widget.password!,
          termsAccepted: termsAccepted,
          privacyAcknowledged: privacyAcknowledged,
          termsVersion: termsVersion,
          privacyVersion: privacyVersion,
        );
      }

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
        }
        sharedPrefs.setString("selfieStatus", user.selfieStatus ?? "NONE");

        if (!mounted) return;

        final onboardingStatus = OnboardingStatus(
          id: user.id,
          hasCompletedBasicDetails: user.hasCompletedBasicDetails,
          hasCompletedPartnerPreference: user.hasCompletedPartnerPreference,
          profileStatus: user.profileStatus,
          hasCompletedImageUpload: user.hasCompletedImageUpload,
          selfieStatus: user.selfieStatus,
        );

        context.read<AuthProvider>().loginSuccess(onboardingStatus);
      }
    } catch (e) {
      debugPrint("Auth Error: $e");
      String errorMessage = "Registration failed. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isRegistering = false;
        });
      }
    }
  }

  void _showDocumentScreen(String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullTextScreen(title: title, content: content),
      ),
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
                    onTap: () {
                      // Prevent toggling checkbox when clicking the link
                      onReadMore();
                    },
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
                                onReadMore: () => _showDocumentScreen(
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
                                onReadMore: () => _showDocumentScreen(
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
                                      ? _register
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

class FullTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const FullTextScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: MarkdownBody(
          data: content,
          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
            p: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
            ),
            h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            listBullet: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}
