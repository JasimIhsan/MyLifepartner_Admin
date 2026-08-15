import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/edit_partner_preference_screen/widgets/edit_partner_preference_controller.dart';
import 'package:life_partner_again/screens/edit_partner_preference_screen/widgets/edit_partner_preference_form.dart';

class MobileEditPartnerPreferenceScreen extends StatefulWidget {
  const MobileEditPartnerPreferenceScreen({super.key});

  @override
  State<MobileEditPartnerPreferenceScreen> createState() =>
      _MobileEditPartnerPreferenceScreenState();
}

class _MobileEditPartnerPreferenceScreenState
    extends State<MobileEditPartnerPreferenceScreen>
    with
        EditPartnerPreferenceControllerState<
          MobileEditPartnerPreferenceScreen
        > {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isDirty && !isSaving,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackPress();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: theme.canvasColor,
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                backgroundColor: theme.canvasColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.textTheme.bodyLarge?.color,
                    size: 20,
                  ),
                  onPressed: handleBackPress,
                ),
                actions: [
                  if (isDirty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: isSaving
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : TextButton(
                              onPressed: canSave ? savePartnerPreference : null,
                              child: Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: canSave
                                      ? const Color(
                                          0xFFFF3B30,
                                        ) // Red save button like mockup
                                      : theme.disabledColor,
                                ),
                              ),
                            ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: isInitialLoading
                    ? _buildLoadingState(context)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                        child: EditPartnerPreferenceForm(
                          ageRange: ageRange,
                          onAgeChanged: updateAgeRange,
                          selectedMaritalStatus: maritalStatus,
                          onMaritalStatusToggle: toggleMaritalStatus,
                          selectedLanguages: languages,
                          onLanguageToggle: toggleLanguage,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your preferences...',
              style: TextStyle(
                fontSize: 14,
                color:
                    Theme.of(context).textTheme.bodySmall?.color ??
                    AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
