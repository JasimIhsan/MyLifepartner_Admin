import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/partner_preference/partner_preference_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isLoading = false;
  int _currentStep = 0;
  bool _goingForward = true;

  // Step 0  : First name + Last name + DOB + Country + City
  // Step 1  : Gender + Height
  // Step 2  : Marital status
  // Step 3  : Children
  // Step 4  : Emotional readiness
  // Step 5  : Looking for
  // Step 6  : Relationship timeline
  // Step 7  : Education
  // Step 8  : Profession
  // Step 9  : Languages spoken
  // Step 10 : Smoking
  // Step 11 : Drinking
  static const int _totalSteps = 12;

  // Collected data
  String? _firstName;
  String? _lastName;
  String? _country;
  String? _city;
  String? _gender;
  DateTime? _dateOfBirth;
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

  int? _heightCm;

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _professionCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _professionCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _firstName != null &&
            _firstName!.trim().isNotEmpty &&
            _lastName != null &&
            _lastName!.trim().isNotEmpty &&
            _dateOfBirth != null &&
            _country != null &&
            _country!.trim().isNotEmpty &&
            _city != null &&
            _city!.trim().isNotEmpty;
      case 1:
        return _gender != null && _heightCm != null && _heightCm! > 0;
      case 2:
        return _maritalStatus != null;
      case 3:
        return _childrenStatus != null;
      case 4:
        return _emotionalReadiness != null;
      case 5:
        return _lookingFor != null;
      case 6:
        return _relationshipTimeline != null;
      case 7:
        return _highestEducation != null;
      case 8:
        return _profession != null && _profession!.trim().isNotEmpty;
      case 9:
        return _languages.isNotEmpty;
      case 10:
        return _smokingHabit != null;
      case 11:
        return _drinkingHabit != null;
      default:
        return false;
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
      final fullName =
          '${_firstName!.trim()} ${_lastName!.trim()}'.trim();

      await _profileRepo.updateBasicProfile({
        'name': fullName,
        'gender': _gender,
        'dateOfBirth':
            _dateOfBirth != null ? '${_dateOfBirth!.toIso8601String()}Z' : null,
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
      await prefs.setString('name', fullName);

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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _stepHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _optionCard({
    required String label,
    required String value,
    required String? selectedValue,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.words,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      style: GoogleFonts.poppins(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(
            color: AppColors.textSecondary, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 15),
      ),
      onChanged: onChanged,
    );
  }

  // ─── Steps ────────────────────────────────────────────────────────────────

  // Step 0 — Name + Location
  Widget _buildBasicInfoStep() {
    return _StepContainer(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "Let's get to know you",
            subtitle: "Tell us a little about yourself to get started.",
          ),
          const SizedBox(height: 28),

          // Name row
          _sectionLabel("Your name"),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  controller: _firstNameCtrl,
                  hint: 'First name',
                  onChanged: (v) =>
                      setState(() => _firstName = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputField(
                  controller: _lastNameCtrl,
                  hint: 'Last name',
                  onChanged: (v) =>
                      setState(() => _lastName = v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Date of birth
          _sectionLabel("Date of birth"),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateOfBirth ??
                    DateTime.now().subtract(const Duration(days: 365 * 30)),
                firstDate: DateTime(1930),
                lastDate:
                    DateTime.now().subtract(const Duration(days: 365 * 18)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: AppColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _dateOfBirth = picked);
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _dateOfBirth != null
                      ? AppColors.primary
                      : AppColors.borderColor,
                  width: _dateOfBirth != null ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    _dateOfBirth == null
                        ? 'Select date of birth'
                        : '${_dateOfBirth!.day} / ${_dateOfBirth!.month} / ${_dateOfBirth!.year}',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: _dateOfBirth != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Location
          _sectionLabel("Where do you live?"),
          const SizedBox(height: 10),
          _countryPicker(),
          const SizedBox(height: 12),
          _inputField(
            controller: _cityCtrl,
            hint: 'City',
            onChanged: (v) => setState(() => _city = v),
          ),
        ],
      ),
    );
  }

  Widget _countryPicker() {
    return GestureDetector(
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _CountryPickerSheet(selected: _country),
        );
        if (selected != null) {
          setState(() {
            _country = selected;
            _countryCtrl.text = selected;
          });
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: _country != null
                ? AppColors.primary
                : AppColors.borderColor,
            width: _country != null ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _country ?? 'Country',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: _country != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  // Step 1 — Gender + Height
  Widget _buildGenderStep() {
    return _StepContainer(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("Tell us about yourself"),
          const SizedBox(height: 32),
          _sectionLabel("Your gender"),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _genderOption('Male', 'MALE'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _genderOption('Female', 'FEMALE'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _genderOption('Other', 'OTHER'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _sectionLabel("Your height (cm)"),
          const SizedBox(height: 12),
          _inputField(
            controller: _heightCtrl,
            hint: 'e.g. 175',
            keyboardType: TextInputType.number,
            onChanged: (v) {
              setState(() {
                _heightCm = int.tryParse(v);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _genderOption(String label, String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // Step 2 — Marital status
  Widget _buildMaritalStatusStep() {
    const options = [
      ('Never Married', 'NEVER_MARRIED'),
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Legally Separated', 'LEGALLY_SEPARATED'),
    ];
    return _StepContainer(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("What's your marital status?"),
          const SizedBox(height: 32),
          for (final (label, value) in options)
            _optionCard(
              label: label,
              value: value,
              selectedValue: _maritalStatus,
              onTap: () => setState(() => _maritalStatus = value),
            ),
        ],
      ),
    );
  }

  // Step 3 — Children
  Widget _buildChildrenStep() {
    return _StepContainer(
      key: const ValueKey(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("Do you have children?"),
          const SizedBox(height: 32),
          _optionCard(
            label: 'Yes — living with me',
            value: 'LIVING_WITH_ME',
            selectedValue: _childrenStatus,
            onTap: () =>
                setState(() => _childrenStatus = 'LIVING_WITH_ME'),
          ),
          _optionCard(
            label: 'Yes — not living with me',
            value: 'NOT_LIVING_WITH_ME',
            selectedValue: _childrenStatus,
            onTap: () =>
                setState(() => _childrenStatus = 'NOT_LIVING_WITH_ME'),
          ),
          _optionCard(
            label: 'No',
            value: 'NO_CHILDREN',
            selectedValue: _childrenStatus,
            onTap: () =>
                setState(() => _childrenStatus = 'NO_CHILDREN'),
          ),
        ],
      ),
    );
  }

  // Step 5 — Emotional readiness
  Widget _buildEmotionalReadinessStep() {
    return _StepContainer(
      key: const ValueKey(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
              "Are you emotionally ready for a serious relationship?"),
          const SizedBox(height: 32),
          _optionCard(
            label: 'Yes, absolutely',
            value: 'YES',
            selectedValue: _emotionalReadiness,
            onTap: () =>
                setState(() => _emotionalReadiness = 'YES'),
          ),
          _optionCard(
            label: 'Mostly ready',
            value: 'MOSTLY',
            selectedValue: _emotionalReadiness,
            onTap: () =>
                setState(() => _emotionalReadiness = 'MOSTLY'),
          ),
          _optionCard(
            label: "I'm not sure yet",
            value: 'NOT_SURE',
            selectedValue: _emotionalReadiness,
            onTap: () =>
                setState(() => _emotionalReadiness = 'NOT_SURE'),
          ),
        ],
      ),
    );
  }

  // Step 6 — Looking for
  Widget _buildLookingForStep() {
    return _StepContainer(
      key: const ValueKey(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "What are you looking for?",
            subtitle:
                "Be honest — it helps us find the right person for you.",
          ),
          const SizedBox(height: 32),
          _optionCard(
            label: 'Marriage',
            value: 'MARRIAGE',
            selectedValue: _lookingFor,
            onTap: () => setState(() => _lookingFor = 'MARRIAGE'),
          ),
          _optionCard(
            label: 'Long-term committed relationship',
            value: 'LONG_TERM_RELATIONSHIP',
            selectedValue: _lookingFor,
            onTap: () => setState(
                () => _lookingFor = 'LONG_TERM_RELATIONSHIP'),
          ),
          _optionCard(
            label: 'Serious companionship',
            value: 'SERIOUS_COMPANIONSHIP',
            selectedValue: _lookingFor,
            onTap: () => setState(
                () => _lookingFor = 'SERIOUS_COMPANIONSHIP'),
          ),
        ],
      ),
    );
  }

  // Step 7 — Timeline
  Widget _buildTimelineStep() {
    return _StepContainer(
      key: const ValueKey(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "What's your preferred timeline?",
            subtitle: "When do you see yourself settling down?",
          ),
          const SizedBox(height: 32),
          _optionCard(
            label: 'Within 0–6 months',
            value: 'ZERO_TO_SIX_MONTHS',
            selectedValue: _relationshipTimeline,
            onTap: () => setState(
                () => _relationshipTimeline = 'ZERO_TO_SIX_MONTHS'),
          ),
          _optionCard(
            label: 'Within 6–12 months',
            value: 'SIX_TO_TWELVE_MONTHS',
            selectedValue: _relationshipTimeline,
            onTap: () => setState(
                () => _relationshipTimeline = 'SIX_TO_TWELVE_MONTHS'),
          ),
          _optionCard(
            label: 'No fixed timeline',
            value: 'NO_FIXED_TIMELINE',
            selectedValue: _relationshipTimeline,
            onTap: () => setState(
                () => _relationshipTimeline = 'NO_FIXED_TIMELINE'),
          ),
        ],
      ),
    );
  }

  // Step 8 — Education
  Widget _buildEducationStep() {
    const options = [
      ('High School / Secondary', 'HIGH_SCHOOL'),
      ('Vocational / Diploma', 'VOCATIONAL'),
      ("Bachelor's Degree", 'BACHELORS'),
      ("Master's Degree", 'MASTERS'),
      ('Doctorate / PhD', 'DOCTORATE'),
      ('Medical Degree', 'MEDICAL'),
      ('Law Degree', 'LAW'),
      ('Other', 'OTHER'),
    ];
    return _StepContainer(
      key: const ValueKey(7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("What's your highest education?"),
          const SizedBox(height: 32),
          for (final (label, value) in options)
            _optionCard(
              label: label,
              value: value,
              selectedValue: _highestEducation,
              onTap: () =>
                  setState(() => _highestEducation = value),
            ),
        ],
      ),
    );
  }

  // Step 9 — Profession
  Widget _buildProfessionStep() {
    return _StepContainer(
      key: const ValueKey(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "What do you do for work?",
            subtitle: "Your profession or industry.",
          ),
          const SizedBox(height: 32),
          _inputField(
            controller: _professionCtrl,
            hint: 'e.g. Software Engineer, Doctor, Teacher…',
            capitalization: TextCapitalization.sentences,
            onChanged: (v) => setState(() => _profession = v),
          ),
        ],
      ),
    );
  }

  // Step 10 — Languages
  Widget _buildLanguagesStep() {
    const langs = [
      'English', 'Arabic', 'Hindi', 'Urdu', 'Bengali',
      'Mandarin', 'Spanish', 'French', 'Portuguese', 'Russian',
      'German', 'Japanese', 'Korean', 'Turkish', 'Italian',
      'Malay', 'Swahili', 'Punjabi', 'Tamil', 'Other',
    ];
    return _StepContainer(
      key: const ValueKey(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "What languages do you speak?",
            subtitle: "Select all that apply.",
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: langs.map((lang) {
              final selected = _languages.contains(lang);
              return GestureDetector(
                onTap: () => setState(() {
                  selected
                      ? _languages.remove(lang)
                      : _languages.add(lang);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.borderColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    lang,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 11 — Smoking
  Widget _buildSmokingStep() {
    return _StepContainer(
      key: const ValueKey(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("Do you smoke?"),
          const SizedBox(height: 32),
          _optionCard(
            label: 'No',
            value: 'NO',
            selectedValue: _smokingHabit,
            onTap: () => setState(() => _smokingHabit = 'NO'),
          ),
          _optionCard(
            label: 'Occasionally',
            value: 'OCCASIONALLY',
            selectedValue: _smokingHabit,
            onTap: () =>
                setState(() => _smokingHabit = 'OCCASIONALLY'),
          ),
          _optionCard(
            label: 'Yes',
            value: 'YES',
            selectedValue: _smokingHabit,
            onTap: () => setState(() => _smokingHabit = 'YES'),
          ),
        ],
      ),
    );
  }

  // Step 12 — Drinking
  Widget _buildDrinkingStep() {
    return _StepContainer(
      key: const ValueKey(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader("Do you drink alcohol?"),
          const SizedBox(height: 32),
          _optionCard(
            label: 'No',
            value: 'NO',
            selectedValue: _drinkingHabit,
            onTap: () => setState(() => _drinkingHabit = 'NO'),
          ),
          _optionCard(
            label: 'Socially',
            value: 'SOCIALLY',
            selectedValue: _drinkingHabit,
            onTap: () =>
                setState(() => _drinkingHabit = 'SOCIALLY'),
          ),
          _optionCard(
            label: 'Yes',
            value: 'YES',
            selectedValue: _drinkingHabit,
            onTap: () => setState(() => _drinkingHabit = 'YES'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildGenderStep();
      case 2:
        return _buildMaritalStatusStep();
      case 3:
        return _buildChildrenStep();
      case 4:
        return _buildEmotionalReadinessStep();
      case 5:
        return _buildLookingForStep();
      case 6:
        return _buildTimelineStep();
      case 7:
        return _buildEducationStep();
      case 8:
        return _buildProfessionStep();
      case 9:
        return _buildLanguagesStep();
      case 10:
        return _buildSmokingStep();
      case 11:
        return _buildDrinkingStep();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 20),
                onPressed: _back,
              )
            : const SizedBox.shrink(),
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Icon(Icons.logout,
                color: AppColors.textSecondary, size: 20),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: AppColors.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Step content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: _goingForward
                        ? const Offset(0.06, 0)
                        : const Offset(-0.06, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                        position: slide, child: child),
                  );
                },
                child: _buildCurrentStep(),
              ),
            ),

            // Continue / Finish button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_canProceed && !_isLoading) ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderColor,
                    disabledForegroundColor: AppColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                          ? 'Finish'
                          : 'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Country picker bottom sheet ───────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final String? selected;
  const _CountryPickerSheet({this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<String> _filtered = _kCountries;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _kCountries
          : _kCountries
              .where((c) => c.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Country',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              // Search
              TextField(
                controller: _search,
                onChanged: _onSearch,
                autofocus: true,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textSecondary, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final country = _filtered[i];
                    final isSelected = country == widget.selected;
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        country,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              color: AppColors.primary, size: 18)
                          : null,
                      onTap: () => Navigator.pop(context, country),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const List<String> _kCountries = [
  'Afghanistan', 'Albania', 'Algeria', 'Andorra', 'Angola',
  'Antigua and Barbuda', 'Argentina', 'Armenia', 'Australia', 'Austria',
  'Azerbaijan', 'Bahamas', 'Bahrain', 'Bangladesh', 'Barbados',
  'Belarus', 'Belgium', 'Belize', 'Benin', 'Bhutan',
  'Bolivia', 'Bosnia and Herzegovina', 'Botswana', 'Brazil', 'Brunei',
  'Bulgaria', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cambodia',
  'Cameroon', 'Canada', 'Central African Republic', 'Chad', 'Chile',
  'China', 'Colombia', 'Comoros', 'Congo', 'Costa Rica',
  'Croatia', 'Cuba', 'Cyprus', 'Czech Republic', 'Denmark',
  'Djibouti', 'Dominica', 'Dominican Republic', 'Ecuador', 'Egypt',
  'El Salvador', 'Equatorial Guinea', 'Eritrea', 'Estonia', 'Eswatini',
  'Ethiopia', 'Fiji', 'Finland', 'France', 'Gabon',
  'Gambia', 'Georgia', 'Germany', 'Ghana', 'Greece',
  'Grenada', 'Guatemala', 'Guinea', 'Guinea-Bissau', 'Guyana',
  'Haiti', 'Honduras', 'Hungary', 'Iceland', 'India',
  'Indonesia', 'Iran', 'Iraq', 'Ireland', 'Israel',
  'Italy', 'Jamaica', 'Japan', 'Jordan', 'Kazakhstan',
  'Kenya', 'Kiribati', 'Kuwait', 'Kyrgyzstan', 'Laos',
  'Latvia', 'Lebanon', 'Lesotho', 'Liberia', 'Libya',
  'Liechtenstein', 'Lithuania', 'Luxembourg', 'Madagascar', 'Malawi',
  'Malaysia', 'Maldives', 'Mali', 'Malta', 'Marshall Islands',
  'Mauritania', 'Mauritius', 'Mexico', 'Micronesia', 'Moldova',
  'Monaco', 'Mongolia', 'Montenegro', 'Morocco', 'Mozambique',
  'Myanmar', 'Namibia', 'Nauru', 'Nepal', 'Netherlands',
  'New Zealand', 'Nicaragua', 'Niger', 'Nigeria', 'North Korea',
  'North Macedonia', 'Norway', 'Oman', 'Pakistan', 'Palau',
  'Palestine', 'Panama', 'Papua New Guinea', 'Paraguay', 'Peru',
  'Philippines', 'Poland', 'Portugal', 'Qatar', 'Romania',
  'Russia', 'Rwanda', 'Saint Kitts and Nevis', 'Saint Lucia',
  'Saint Vincent and the Grenadines', 'Samoa', 'San Marino',
  'Sao Tome and Principe', 'Saudi Arabia', 'Senegal', 'Serbia',
  'Seychelles', 'Sierra Leone', 'Singapore', 'Slovakia', 'Slovenia',
  'Solomon Islands', 'Somalia', 'South Africa', 'South Korea',
  'South Sudan', 'Spain', 'Sri Lanka', 'Sudan', 'Suriname',
  'Sweden', 'Switzerland', 'Syria', 'Taiwan', 'Tajikistan',
  'Tanzania', 'Thailand', 'Timor-Leste', 'Togo', 'Tonga',
  'Trinidad and Tobago', 'Tunisia', 'Turkey', 'Turkmenistan', 'Tuvalu',
  'Uganda', 'Ukraine', 'United Arab Emirates', 'United Kingdom',
  'United States', 'Uruguay', 'Uzbekistan', 'Vanuatu', 'Vatican City',
  'Venezuela', 'Vietnam', 'Yemen', 'Zambia', 'Zimbabwe',
];

// ── Step container ────────────────────────────────────────────────────────────
class _StepContainer extends StatelessWidget {
  final Widget child;

  const _StepContainer({required super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: child,
    );
  }
}
