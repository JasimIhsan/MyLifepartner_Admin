
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_steps.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
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
    switch (_currentStep) {
      case 0:
        return _firstName != null &&
            _firstName!.isNotEmpty &&
            _lastName != null &&
            _lastName!.isNotEmpty &&
            _dateOfBirth != null;
      case 1:
        return _gender != null;
      case 2:
        return _maritalStatus != null;
      case 3:
        return _country != null && _city != null && _city!.isNotEmpty;
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
        return _profession != null && _profession!.isNotEmpty;
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
      child: Row(
        children: [
          IconButton(
            onPressed: _currentStep == 0 ? null : _back,
            icon: Icon(
              _currentStep == 0
                  ? Icons.close
                  : Icons.arrow_back_ios_new_rounded,
              size: 20,
            ),
            color: Colors.black87,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }


  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return BasicInfoStep(
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          dateOfBirth: _dateOfBirth,
          onFirstNameChanged: (v) => setState(() => _firstName = v),
          onLastNameChanged: (v) => setState(() => _lastName = v),
          onDateOfBirthChanged: (d) => setState(() => _dateOfBirth = d),
        );
      case 1:
        return GenderStep(
          selectedGender: _gender,
          onGenderChanged: (v) => setState(() => _gender = v),
        );
      case 2:
        return MaritalStatusStep(
          selectedMaritalStatus: _maritalStatus,
          onMaritalStatusChanged: (v) => setState(() => _maritalStatus = v),
        );
      case 3:
        return LocationStep(
          country: _country,
          cityCtrl: _cityCtrl,
          onCountryChanged: (v) => setState(() {
            _country = v;
            _countryCtrl.text = v;
          }),
          onCityChanged: (v) => setState(() => _city = v),
        );
      case 4:
        return EmotionalReadinessStep(
          selectedReadiness: _emotionalReadiness,
          onReadinessChanged: (v) => setState(() => _emotionalReadiness = v),
        );
      case 5:
        return LanguagesStep(
          selectedLanguages: _languages,
          onLanguageToggled: (l) => setState(() {
            if (_languages.contains(l)) {
              _languages.remove(l);
            } else {
              _languages.add(l);
            }
          }),
        );
      case 6:
        return ChildrenStep(
          selectedChildrenStatus: _childrenStatus,
          onChildrenStatusChanged: (v) => setState(() => _childrenStatus = v),
        );
      case 7:
        return HeightStep(
          heightCm: _heightCm,
          onHeightChanged: (v) => setState(() {
            _heightCm = v;
            _heightCtrl.text = v.toString();
          }),
        );
      case 8:
        return LookingForStep(
          selectedLookingFor: _lookingFor,
          onLookingForChanged: (v) => setState(() => _lookingFor = v),
        );
      case 9:
        return EducationStep(
          selectedEducation: _highestEducation,
          onEducationChanged: (v) => setState(() => _highestEducation = v),
        );
      case 10:
        return ProfessionStep(
          professionCtrl: _professionCtrl,
          onProfessionChanged: (v) => setState(() => _profession = v),
        );
      case 11:
        return HabitsStep(
          drinkingHabit: _drinkingHabit,
          smokingHabit: _smokingHabit,
          onDrinkingChanged: (v) => setState(() => _drinkingHabit = v),
          onSmokingChanged: (v) => setState(() => _smokingHabit = v),
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
