import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/basic_info_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/children_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/education_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/emotional_readiness_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/gender_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/habits_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/height_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/languages_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/location_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/looking_for_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/marital_status_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import 'package:life_partner_again/screens/onboarding/widgets/profession_step.dart';
import 'package:life_partner_again/screens/partner_preference/partner_preference_screen.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  final int _totalSteps = 12;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _goingForward = true;

  // Form controllers
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _professionCtrl = TextEditingController();

  // Selected values
  String? _firstName;
  String? _lastName;
  DateTime? _dateOfBirth;
  String? _gender;
  String? _country;
  String? _city;
  int? _heightCm;
  String? _maritalStatus;
  String? _childrenStatus;
  String? _emotionalReadiness;
  String? _lookingFor;
  String? _relationshipTimeline;
  String? _highestEducation;
  String? _profession;
  final List<String> _languages = [];
  String? _smokingHabit;
  String? _drinkingHabit;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstName = prefs.getString('onboarding_first_name');
      _lastName = prefs.getString('onboarding_last_name');
      _firstNameCtrl.text = _firstName ?? '';
      _lastNameCtrl.text = _lastName ?? '';

      final dobStr = prefs.getString('onboarding_date_of_birth');
      if (dobStr != null) {
        _dateOfBirth = DateTime.tryParse(dobStr);
      }

      _gender = prefs.getString('onboarding_gender');
      _country = prefs.getString('onboarding_country');
      _countryCtrl.text = _country ?? '';

      _city = prefs.getString('onboarding_city');
      _cityCtrl.text = _city ?? '';

      _heightCm = prefs.getInt('onboarding_height_cm');
      if (_heightCm != null) {
        _heightCtrl.text = _heightCm.toString();
      }

      _maritalStatus = prefs.getString('onboarding_marital_status');
      _childrenStatus = prefs.getString('onboarding_children_status');
      _emotionalReadiness = prefs.getString('onboarding_emotional_readiness');
      _lookingFor = prefs.getString('onboarding_looking_for');
      _highestEducation = prefs.getString('onboarding_highest_education');

      _profession = prefs.getString('onboarding_profession');
      _professionCtrl.text = _profession ?? '';

      final langs = prefs.getStringList('onboarding_languages');
      if (langs != null) {
        _languages.clear();
        _languages.addAll(langs);
      }

      _smokingHabit = prefs.getString('onboarding_smoking_habit');
      _drinkingHabit = prefs.getString('onboarding_drinking_habit');

      _currentStep = prefs.getInt('onboarding_current_step') ?? 0;
    });
  }

  Future<void> _saveToCache(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  Future<void> _clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'onboarding_first_name',
      'onboarding_last_name',
      'onboarding_date_of_birth',
      'onboarding_gender',
      'onboarding_country',
      'onboarding_city',
      'onboarding_height_cm',
      'onboarding_marital_status',
      'onboarding_children_status',
      'onboarding_emotional_readiness',
      'onboarding_looking_for',
      'onboarding_highest_education',
      'onboarding_profession',
      'onboarding_languages',
      'onboarding_smoking_habit',
      'onboarding_drinking_habit',
      'onboarding_current_step',
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _heightCtrl.dispose();
    _professionCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\']+$");
    final cityRegex = RegExp(r"^[a-zA-Z\s\-\'\.]+$");
    final professionRegex = RegExp(r"^[a-zA-Z0-9\s\-\'\.\,]+$");

    switch (_currentStep) {
      case 0:
        return _firstName != null &&
            nameRegex.hasMatch(_firstName!.trim()) &&
            _lastName != null &&
            nameRegex.hasMatch(_lastName!.trim()) &&
            _dateOfBirth != null;
      case 1:
        return _gender != null;
      case 2:
        return _maritalStatus != null;
      case 3:
        return _country != null &&
            _city != null &&
            cityRegex.hasMatch(_city!.trim());
      case 4:
        return _emotionalReadiness != null;
      case 5:
        return _languages.isNotEmpty;
      case 6:
        return _childrenStatus != null;
      case 7:
        return _heightCm != null;
      case 8:
        return _lookingFor != null;
      case 9:
        return _highestEducation != null;
      case 10:
        return _profession != null &&
            professionRegex.hasMatch(_profession!.trim());
      case 11:
        return _smokingHabit != null && _drinkingHabit != null;
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
      _saveToCache('onboarding_current_step', _currentStep);
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
      _saveToCache('onboarding_current_step', _currentStep);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final name = '${_firstName?.trim() ?? ""} ${_lastName?.trim() ?? ""}'
          .trim();
      await _profileRepo.updateBasicProfile({
        'name': name,
        'gender': _gender,
        'dateOfBirth': _dateOfBirth != null
            ? '${_dateOfBirth!.toIso8601String()}Z'
            : null,
        'country': _country,
        'city': _city,
        'heightCm': _heightCm,
        'maritalStatus': _maritalStatus,
        'childrenStatus': _childrenStatus,
        'emotionalReadiness': _emotionalReadiness,
        'lookingFor': _lookingFor,
        'relationshipTimeline': _relationshipTimeline,
        'highestEducation': _highestEducation,
        'occupation': _profession,
        'languages': _languages,
        'smokingHabit': _smokingHabit,
        'drinkingHabit': _drinkingHabit,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await _clearCachedData();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PartnerPreferenceScreen()),
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

  // ─── Shared UI Components ──────────────────────────────────────────────────

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        height: 48, // keeps navbar height stable
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_currentStep > 0)
              IconButton(
                onPressed: _back,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.black87,
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
        return BasicInfoStep(
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          dateOfBirth: _dateOfBirth,
          onFirstNameChanged: (v) {
            setState(() => _firstName = v);
            _saveToCache('onboarding_first_name', v);
          },
          onLastNameChanged: (v) {
            setState(() => _lastName = v);
            _saveToCache('onboarding_last_name', v);
          },
          onDateOfBirthChanged: (d) {
            setState(() => _dateOfBirth = d);
            _saveToCache('onboarding_date_of_birth', d.toIso8601String());
          },
        );
      case 1:
        return GenderStep(
          selectedGender: _gender,
          onGenderChanged: (v) {
            setState(() => _gender = v);
            _saveToCache('onboarding_gender', v);
          },
        );
      case 2:
        return MaritalStatusStep(
          selectedMaritalStatus: _maritalStatus,
          onMaritalStatusChanged: (v) {
            setState(() => _maritalStatus = v);
            _saveToCache('onboarding_marital_status', v);
          },
        );
      case 3:
        return LocationStep(
          country: _country,
          cityCtrl: _cityCtrl,
          onCountryChanged: (v) {
            setState(() {
              _country = v;
              _countryCtrl.text = v;
            });
            _saveToCache('onboarding_country', v);
          },
          onCityChanged: (v) {
            setState(() => _city = v);
            _saveToCache('onboarding_city', v);
          },
        );
      case 4:
        return EmotionalReadinessStep(
          selectedReadiness: _emotionalReadiness,
          onReadinessChanged: (v) {
            setState(() => _emotionalReadiness = v);
            _saveToCache('onboarding_emotional_readiness', v);
          },
        );
      case 5:
        return LanguagesStep(
          selectedLanguages: _languages,
          onLanguageToggled: (l) {
            setState(() {
              if (_languages.contains(l)) {
                _languages.remove(l);
              } else {
                _languages.add(l);
              }
            });
            _saveToCache('onboarding_languages', _languages);
          },
        );
      case 6:
        return ChildrenStep(
          selectedChildrenStatus: _childrenStatus,
          onChildrenStatusChanged: (v) {
            setState(() => _childrenStatus = v);
            _saveToCache('onboarding_children_status', v);
          },
        );
      case 7:
        return HeightStep(
          heightCm: _heightCm,
          onHeightChanged: (v) {
            setState(() {
              _heightCm = v;
              _heightCtrl.text = v.toString();
            });
            _saveToCache('onboarding_height_cm', v);
          },
        );
      case 8:
        return LookingForStep(
          selectedLookingFor: _lookingFor,
          onLookingForChanged: (v) {
            setState(() => _lookingFor = v);
            _saveToCache('onboarding_looking_for', v);
          },
        );
      case 9:
        return EducationStep(
          selectedEducation: _highestEducation,
          onEducationChanged: (v) {
            setState(() => _highestEducation = v);
            _saveToCache('onboarding_highest_education', v);
          },
        );
      case 10:
        return ProfessionStep(
          professionCtrl: _professionCtrl,
          onProfessionChanged: (v) {
            setState(() => _profession = v);
            _saveToCache('onboarding_profession', v);
          },
        );
      case 11:
        return HabitsStep(
          drinkingHabit: _drinkingHabit,
          smokingHabit: _smokingHabit,
          onDrinkingChanged: (v) {
            setState(() => _drinkingHabit = v);
            _saveToCache('onboarding_drinking_habit', v);
          },
          onSmokingChanged: (v) {
            setState(() => _smokingHabit = v);
            _saveToCache('onboarding_smoking_habit', v);
          },
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    final offsetBegin = _goingForward
                        ? const Offset(0.1, 0)
                        : const Offset(-0.1, 0);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
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
            OnboardingContinueButton(
              canProceed: _canProceed,
              isLoading: _isLoading,
              isLastStep: _currentStep == _totalSteps - 1,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}
