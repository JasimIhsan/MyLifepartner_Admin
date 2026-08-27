import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/edit_partner_preference_screen/widgets/edit_partner_preference_controller.dart';
import 'package:life_partner_again/screens/edit_partner_preference_screen/widgets/web_edit_partner_preference_form.dart';

class WebEditPartnerPreferenceScreen extends StatefulWidget {
  const WebEditPartnerPreferenceScreen({super.key});

  @override
  State<WebEditPartnerPreferenceScreen> createState() =>
      _WebEditPartnerPreferenceScreenState();
}

class _WebEditPartnerPreferenceScreenState
    extends State<WebEditPartnerPreferenceScreen>
    with EditPartnerPreferenceControllerState<WebEditPartnerPreferenceScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFFFF3B30); // Red

    return PopScope(
      canPop: !isDirty && !isSaving,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackPress();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5), // grey background
        body: isInitialLoading
            ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
            : Center(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Side Banner
                          Container(
                            width: 320,
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height - 80, // rough height minus appbar
                            ),
                            color: const Color(0xFFFFF0F0),
                            padding: const EdgeInsets.all(40),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 60),
                                    Text(
                                      "Let's find\nyour perfect\nmatch",
                                      style: TextStyle(
                                        fontSize: 32,
                                        height: 1.2,
                                        fontWeight: FontWeight.w800,
                                        color: theme.textTheme.titleLarge?.color ??
                                            Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                // Decorative Hearts
                                Positioned(
                                  bottom: 80,
                                  right: 30,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primary.withValues(alpha: 0.15),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.favorite, size: 40, color: primary.withValues(alpha: 0.8)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 60,
                                  left: 20,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primary.withValues(alpha: 0.1),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.favorite, size: 24, color: primary.withValues(alpha: 0.6)),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 150,
                                  left: 100,
                                  child: Icon(Icons.favorite, size: 20, color: primary.withValues(alpha: 0.3)),
                                ),
                              ],
                            ),
                          ),
                          // Divider
                          Container(
                            width: 1,
                            color: theme.dividerColor.withValues(alpha: 0.2),
                          ),
                          // Right Side Form
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(48.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  WebEditPartnerPreferenceForm(
                                    ageRange: ageRange,
                                    onAgeChanged: updateAgeRange,
                                    selectedMaritalStatus: maritalStatus,
                                    onMaritalStatusToggle: toggleMaritalStatus,
                                    selectedLanguages: languages,
                                    onLanguageToggle: toggleLanguage,
                                  ),
                                  const SizedBox(height: 48),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      width: 180,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: canSave ? savePartnerPreference : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: primary
                                              .withValues(alpha: 0.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: isSaving
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'Save Changes',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
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
      ),
    );
  }
}
