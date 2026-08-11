import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/edit_partner_preference_screen/widgets/edit_partner_preference_controller.dart';
import 'package:life_partner_again/screens/edit_partner_preference_screen/widgets/edit_partner_preference_form.dart';
import 'package:life_partner_again/widgets/custom_app_bar.dart';

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

    return PopScope(
      canPop: !isDirty && !isSaving,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackPress();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Edit Partner Preferences',
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary,
            ),
            onPressed: handleBackPress,
          ),
        ),
        body: isInitialLoading
            ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 48,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 820),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: theme.primaryColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Partner Preferences',
                                    style: TextStyle(
                                      color: theme.textTheme.titleLarge?.color,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fine tune the matches recommended for you.',
                                    style: TextStyle(
                                      color:
                                          theme.textTheme.bodyMedium?.color ??
                                          AppColors.textSecondary,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        EditPartnerPreferenceForm(
                          ageRange: ageRange,
                          onAgeChanged: updateAgeRange,
                          selectedMaritalStatus: maritalStatus,
                          onMaritalStatusToggle: toggleMaritalStatus,
                          selectedLanguages: languages,
                          onLanguageToggle: toggleLanguage,
                        ),
                        const SizedBox(height: 32),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 210,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: canSave ? savePartnerPreference : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: theme.colorScheme.onPrimary,
                                disabledBackgroundColor: theme.primaryColor
                                    .withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27),
                                ),
                                elevation: 0,
                              ),
                              child: isSaving
                                  ? SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.onPrimary,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_outlined, size: 21),
                                        SizedBox(width: 10),
                                        Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
