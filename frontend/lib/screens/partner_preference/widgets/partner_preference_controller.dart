import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/age_pref_step.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/languages_pref_step.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/marital_pref_step.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin PartnerPreferenceControllerState<T extends StatefulWidget> on State<T> {
  final ProfileRepository profileRepo = ProfileRepository();
  bool isLoading = false;
  int currentStep = 0;
  bool goingForward = true;

  final int totalSteps = 3;

  // Data
  RangeValues ageRange = const RangeValues(25, 45);
  final List<String> maritalStatus = [];
  final List<String> languages = [];

  @override
  void initState() {
    super.initState();
    loadCachedData();
  }

  Future<void> loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final ageStart = prefs.getDouble('pref_age_start') ?? 25.0;
      final ageEnd = prefs.getDouble('pref_age_end') ?? 45.0;
      ageRange = RangeValues(ageStart, ageEnd);

      final marital = prefs.getStringList('pref_marital_status');
      if (marital != null) {
        maritalStatus.clear();
        maritalStatus.addAll(marital);
      }

      final langs = prefs.getStringList('pref_languages');
      if (langs != null) {
        languages.clear();
        languages.addAll(langs);
      }

      currentStep = prefs.getInt('pref_current_step') ?? 0;
    });
  }

  Future<void> saveToCache(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  Future<void> clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'pref_age_start',
      'pref_age_end',
      'pref_marital_status',
      'pref_languages',
      'pref_current_step',
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  bool get isCurrentStepValid {
    switch (currentStep) {
      case 1:
        return maritalStatus.isNotEmpty;
      case 2:
        return languages.isNotEmpty;
      default:
        return true;
    }
  }

  void next() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        goingForward = true;
        currentStep++;
      });
      saveToCache('pref_current_step', currentStep);
    } else {
      submit();
    }
  }

  void back() {
    if (currentStep > 0) {
      setState(() {
        goingForward = false;
        currentStep--;
      });
      saveToCache('pref_current_step', currentStep);
    }
  }

  Future<void> submit() async {
    setState(() => isLoading = true);
    try {
      await profileRepo.updatePartnerPreference({
        'ageFrom': ageRange.start.round(),
        'ageTo': ageRange.end.round(),
        'maritalStatus': maritalStatus,
        'motherTongue': languages,
      });

      await clearCachedData();

      if (mounted) {
        await context.read<AuthProvider>().bootstrap();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void toggle(List<String> list, String value, String cacheKey) {
    setState(() {
      list.contains(value) ? list.remove(value) : list.add(value);
    });
    saveToCache(cacheKey, list);
  }

  String getPrefTitle(int step) {
    switch (step) {
      case 0:
        return "Preferred Age";
      case 1:
        return "Marital Status";
      case 2:
        return "Languages / Mother Tongue";
      default:
        return "Partner Preferences";
    }
  }

  String getPrefDescription(int step) {
    switch (step) {
      case 0:
        return "Select the age range you prefer for your ideal partner.";
      case 1:
        return "Choose one or more acceptable marital status options.";
      case 2:
        return "Select the languages or mother tongues your partner should speak.";
      default:
        return "Set your requirements to find compatible recommendations.";
    }
  }

  Widget buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return AgePrefStep(
          ageRange: ageRange,
          onAgeRangeChanged: (v) {
            setState(() => ageRange = v);
            saveToCache('pref_age_start', v.start);
            saveToCache('pref_age_end', v.end);
          },
        );
      case 1:
        return MaritalPrefStep(
          selectedMaritalStatus: maritalStatus,
          onToggle: (v) => toggle(maritalStatus, v, 'pref_marital_status'),
        );
      case 2:
        return LanguagesPrefStep(
          selectedLanguages: languages,
          onToggle: (v) => toggle(languages, v, 'pref_languages'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> handleBackPress() async {
    if (currentStep > 0) {
      back();
      return;
    }
    if (!mounted) return;
    await CustomBottomSheet.show(
      context: context,
      type: BottomSheetType.confirmation,
      title: 'Exit App',
      message: 'Are you sure you want to exit the app?',
      primaryButtonText: 'Exit',
      onPrimaryPressed: () {
        SystemNavigator.pop();
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        context.pop();
      },
      imagePath: 'assets/images/illustrations/exit.png',
    );
  }
}
