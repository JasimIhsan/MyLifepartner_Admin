import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

import 'package:life_partner_again/screens/partner_preference/widgets/age_pref_step.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/marital_pref_step.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/education_pref_step.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/occupation_pref_step.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/languages_pref_step.dart';
import 'package:life_partner_again/screens/partner_preference/widgets/height_pref_step.dart';

class PartnerPreferenceScreen extends StatefulWidget {
  const PartnerPreferenceScreen({super.key});

  @override
  State<PartnerPreferenceScreen> createState() =>
      _PartnerPreferenceScreenState();
}

class _PartnerPreferenceScreenState extends State<PartnerPreferenceScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isLoading = false;
  int _currentStep = 0;
  bool _goingForward = true;

  static const int _totalSteps = 6;

  // Data
  RangeValues _ageRange = const RangeValues(25, 45);
  RangeValues _heightRange = const RangeValues(150, 185);
  final List<String> _maritalStatus = [];
  final List<String> _education = [];
  final List<String> _occupation = [];
  final List<String> _languages = [];

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final ageStart = prefs.getDouble('pref_age_start') ?? 25.0;
      final ageEnd = prefs.getDouble('pref_age_end') ?? 45.0;
      _ageRange = RangeValues(ageStart, ageEnd);

      final heightStart = prefs.getDouble('pref_height_start') ?? 150.0;
      final heightEnd = prefs.getDouble('pref_height_end') ?? 185.0;
      _heightRange = RangeValues(heightStart, heightEnd);

      final marital = prefs.getStringList('pref_marital_status');
      if (marital != null) {
        _maritalStatus.clear();
        _maritalStatus.addAll(marital);
      }

      final edu = prefs.getStringList('pref_education');
      if (edu != null) {
        _education.clear();
        _education.addAll(edu);
      }

      final occ = prefs.getStringList('pref_occupation');
      if (occ != null) {
        _occupation.clear();
        _occupation.addAll(occ);
      }

      final langs = prefs.getStringList('pref_languages');
      if (langs != null) {
        _languages.clear();
        _languages.addAll(langs);
      }

      _currentStep = prefs.getInt('pref_current_step') ?? 0;
    });
  }

  Future<void> _saveToCache(String key, dynamic value) async {
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

  Future<void> _clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'pref_age_start',
      'pref_age_end',
      'pref_height_start',
      'pref_height_end',
      'pref_marital_status',
      'pref_education',
      'pref_occupation',
      'pref_languages',
      'pref_current_step',
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 2:
        return _maritalStatus.isNotEmpty;
      case 3:
        return _education.isNotEmpty;
      case 4:
        return _occupation.isNotEmpty;
      case 5:
        return _languages.isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _goingForward = true;
        _currentStep++;
      });
      _saveToCache('pref_current_step', _currentStep);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() {
        _goingForward = false;
        _currentStep--;
      });
      _saveToCache('pref_current_step', _currentStep);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await _profileRepo.updatePartnerPreference({
        'ageFrom': _ageRange.start.round(),
        'ageTo': _ageRange.end.round(),
        'heightFrom': _heightRange.start.round(),
        'heightTo': _heightRange.end.round(),
        'maritalStatus': _maritalStatus,
        'highestEducation': _education,
        'occupation': _occupation,
        'motherTongue': _languages,
      });

      await _clearCachedData();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileImageUploadScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggle(List<String> list, String value, String cacheKey) {
    setState(() {
      list.contains(value) ? list.remove(value) : list.add(value);
    });
    _saveToCache(cacheKey, list);
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: _currentStep > 0,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: IconButton(
                onPressed: _back,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: _currentStep > 0 ? 12 : 0,
                  right: 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.borderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return AgePrefStep(
          ageRange: _ageRange,
          onAgeRangeChanged: (v) {
            setState(() => _ageRange = v);
            _saveToCache('pref_age_start', v.start);
            _saveToCache('pref_age_end', v.end);
          },
        );
      case 1:
        return HeightPrefStep(
          heightRange: _heightRange,
          onHeightRangeChanged: (v) {
            setState(() => _heightRange = v);
            _saveToCache('pref_height_start', v.start);
            _saveToCache('pref_height_end', v.end);
          },
        );
      case 2:
        return MaritalPrefStep(
          selectedMaritalStatus: _maritalStatus,
          onToggle: (v) => _toggle(_maritalStatus, v, 'pref_marital_status'),
        );
      case 3:
        return EducationPrefStep(
          selectedEducation: _education,
          onToggle: (v) => _toggle(_education, v, 'pref_education'),
        );
      case 4:
        return OccupationPrefStep(
          selectedOccupation: _occupation,
          onToggle: (v) => _toggle(_occupation, v, 'pref_occupation'),
        );
      case 5:
        return LanguagesPrefStep(
          selectedLanguages: _languages,
          onToggle: (v) => _toggle(_languages, v, 'pref_languages'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigation(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) {
                            final offsetBegin = _goingForward
                                ? const Offset(0.1, 0)
                                : const Offset(-0.1, 0);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: offsetBegin,
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey(_currentStep),
                            child: _buildCurrentStep(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            OnboardingContinueButton(
              canProceed: _isCurrentStepValid,
              isLoading: _isLoading,
              isLastStep: false,
              label: _currentStep == _totalSteps - 1
                  ? 'Continue to Photo Upload'
                  : null,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}
