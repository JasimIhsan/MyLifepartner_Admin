import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
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

  Widget _stepTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.words,
    bool isReadonly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E6E6), width: 1),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadonly,
        onTap: onTap,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        onChanged: onChanged,
        style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: InputBorder.none,
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
        ),
      ),
    );
  }

  Widget _selectionTile({
    required String label,
    required String value,
    required String? selectedValue,
    required VoidCallback onTap,
    String? emoji,
  }) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFF0E6E6),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // if (emoji != null) ...[
            //   Text(emoji, style: const TextStyle(fontSize: 22)),
            //   const SizedBox(width: 12),
            // ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _languageChip(String label) {
    final isSelected = _languages.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _languages.remove(label);
          } else {
            _languages.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        margin: const EdgeInsets.only(right: 10, bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF5F2F2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _continueButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ElevatedButton(
        onPressed: _canProceed ? _next : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _currentStep == _totalSteps - 1 ? 'Finish' : 'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // ─── Steps ────────────────────────────────────────────────────────────────

  Widget _buildBasicInfoStep() {
    return Column(
      children: [
        _stepTitle("Hey! Let's talk little about you"),
        const SizedBox(height: 20),
        _sectionLabel("First Name"),
        _inputField(
          controller: _firstNameCtrl,
          hint: 'First Name',
          onChanged: (v) => setState(() => _firstName = v),
        ),
        const SizedBox(height: 10),
        _sectionLabel("Last Name"),
        _inputField(
          controller: _lastNameCtrl,
          hint: 'Last Name',
          onChanged: (v) => setState(() => _lastName = v),
        ),
        const SizedBox(height: 10),
        _sectionLabel("When is your date of birth?"),
        _inputField(
          controller: TextEditingController(
            text: _dateOfBirth == null
                ? ''
                : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
          ),
          hint: 'DD/MM/YYYY',
          isReadonly: true,
          suffixIcon: const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  _dateOfBirth ??
                  DateTime.now().subtract(const Duration(days: 365 * 25)),
              firstDate: DateTime(1920),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
            );
            if (picked != null) setState(() => _dateOfBirth = picked);
          },
        ),
      ],
    );
  }

  Widget _buildGenderStep() {
    return Column(
      children: [
        _stepTitle("What's your gender?"),
        const SizedBox(height: 20),

        _selectionTile(
          label: 'Man',
          value: 'MALE',
          selectedValue: _gender,
          onTap: () => setState(() => _gender = 'MALE'),
        ),

        _selectionTile(
          label: 'Woman',
          value: 'FEMALE',
          selectedValue: _gender,
          onTap: () => setState(() => _gender = 'FEMALE'),
        ),
      ],
    );
  }

  Widget _buildMaritalStatusStep() {
    const options = [
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Legally Separated', 'LEGALLY_SEPARATED'),
    ];
    return Column(
      children: [
        _stepTitle("What's your marital status?"),
        // _buildIllustration('assets/images/onboarding/marital_status.png'),
        const SizedBox(height: 10),
        for (final (label, value) in options)
          _selectionTile(
            label: label,
            value: value,
            selectedValue: _maritalStatus,
            onTap: () => setState(() => _maritalStatus = value),
          ),
      ],
    );
  }

  Widget _buildLocationStep() {
    return Column(
      children: [
        _stepTitle("Where do you live?"),
        //_buildIllustration('assets/images/onboarding/location.png'),
        const SizedBox(height: 10),
        _sectionLabel("Country"),
        _countryPicker(),
        const SizedBox(height: 10),
        _sectionLabel("City"),
        _inputField(
          controller: _cityCtrl,
          hint: 'Enter your city',
          onChanged: (v) => setState(() => _city = v),
        ),
      ],
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
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E6E6), width: 1),
        ),
        child: Row(
          children: [
            if (_country != null)
              CountryFlag.fromCountryCode(
                _kCountries.firstWhere((c) => c.name == _country).code,
                height: 18,
                width: 26,
              ),
            if (_country != null) const SizedBox(width: 8),
            Expanded(
              child: Text(
                _country ?? 'Select your country',
                style: TextStyle(
                  fontSize: 16,
                  color: _country != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalReadinessStep() {
    return Column(
      children: [
        _stepTitle("Are you ready for a serious relationship?"),
        //_buildIllustration('assets/images/onboarding/relationship.png'),
        const SizedBox(height: 20),
        _selectionTile(
          label: "Yes, I'm ready",
          value: 'YES',
          selectedValue: _emotionalReadiness,
          emoji: '🥰',
          onTap: () => setState(() => _emotionalReadiness = 'YES'),
        ),
        _selectionTile(
          label: "I think so",
          value: 'MOSTLY',
          selectedValue: _emotionalReadiness,
          emoji: '😊',
          onTap: () => setState(() => _emotionalReadiness = 'MOSTLY'),
        ),
        _selectionTile(
          label: "Not sure yet",
          value: 'NOT_SURE',
          selectedValue: _emotionalReadiness,
          emoji: '🤔',
          onTap: () => setState(() => _emotionalReadiness = 'NOT_SURE'),
        ),
      ],
    );
  }

  Widget _buildLanguagesStep() {
    const langs = [
      'English',
      'French',
      'Spanish',
      'German',
      'Italian',
      'Portuguese',
      'Dutch',
      'Russian',
      'Polish',
      'Ukrainian',
      'Romanian',
      'Greek',
      'Turkish',
      'Arabic',
      'Punjabi',
      'Mandarin Chinese',
      'Cantonese',
      'Tagalog',
      'Persian',
      'Urdu',
    ];
    return Column(
      children: [
        _stepTitle("What languages are you comfortable with?"),
        //_buildIllustration(illustration),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          children: langs.map((l) => _languageChip(l)).toList(),
        ),
      ],
    );
  }

  Widget _buildChildrenStep() {
    return Column(
      children: [
        _stepTitle("Do you have children?"),
        //_buildIllustration('assets/images/onboarding/children.png'),
        const SizedBox(height: 32),
        _selectionTile(
          label: 'Yes, living with me',
          value: 'LIVING_WITH_ME',
          selectedValue: _childrenStatus,
          onTap: () => setState(() => _childrenStatus = 'LIVING_WITH_ME'),
        ),
        _selectionTile(
          label: 'Yes, not living with me',
          value: 'NOT_LIVING_WITH_ME',
          selectedValue: _childrenStatus,
          onTap: () => setState(() => _childrenStatus = 'NOT_LIVING_WITH_ME'),
        ),
        _selectionTile(
          label: 'No',
          value: 'NO_CHILDREN',
          selectedValue: _childrenStatus,
          onTap: () => setState(() => _childrenStatus = 'NO_CHILDREN'),
        ),
      ],
    );
  }

  Widget _buildHeightStep() {
    // Height range: 140cm to 220cm
    const minHeight = 140;
    const maxHeight = 220;
    final heights = List.generate(
      maxHeight - minHeight + 1,
      (i) => minHeight + i,
    );

    // If _heightCm is null, default to 170
    if (_heightCm == null) {
      _heightCm = 170;
      _heightCtrl.text = "170";
    }

    String formatImperial(int cm) {
      double totalInches = cm / 2.54;
      int feet = (totalInches / 12).floor();
      int inches = (totalInches % 12).round();
      if (inches == 12) {
        feet++;
        inches = 0;
      }
      return "$feet'$inches\"";
    }

    return Column(
      children: [
        _stepTitle("What is your height?"),
        //_buildIllustration(illustration, height: 140),
        const SizedBox(height: 20),

        // Height Picker
        SizedBox(
          height: 220,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 55,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(
              initialItem: (_heightCm ?? 170) - minHeight,
            ),
            onSelectedItemChanged: (index) {
              setState(() {
                _heightCm = minHeight + index;
                _heightCtrl.text = _heightCm.toString();
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: heights.length,
              builder: (context, index) {
                final cm = heights[index];
                final isSelected = _heightCm == cm;
                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 220 : 180,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${formatImperial(cm)} ($cm cm)",
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 17,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 40),
        // const Spacer(),

        // Bottom Info Card
        // Container(
        //   margin: const EdgeInsets.only(bottom: 20),
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        //   decoration: BoxDecoration(
        //     color: const Color(0xFFF7F7F7),
        //     borderRadius: BorderRadius.circular(12),
        //   ),
        //   child: Row(
        //     children: [
        //       const Icon(Icons.info_outline, size: 20, color: Colors.grey),
        //       const SizedBox(width: 12),
        //       Expanded(
        //         child: Text(
        //           "This info helps us find better matches for you.",
        //           style: TextStyle(
        //             fontSize: 14,
        //             color: Colors.grey[600],
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }

  Widget _buildLookingForStep() {
    return Column(
      children: [
        _stepTitle("What are you looking for?"),
        //_buildIllustration('assets/images/onboarding/relationship.png'),
        const SizedBox(height: 20),
        _selectionTile(
          label: 'Marriage',
          value: 'MARRIAGE',
          selectedValue: _lookingFor,
          onTap: () => setState(() => _lookingFor = 'MARRIAGE'),
        ),
        _selectionTile(
          label: 'Long-term commitment',
          value: 'LONG_TERM_RELATIONSHIP',
          selectedValue: _lookingFor,
          onTap: () => setState(() => _lookingFor = 'LONG_TERM_RELATIONSHIP'),
        ),
        _selectionTile(
          label: 'Serious companionship',
          value: 'SERIOUS_COMPANIONSHIP',
          selectedValue: _lookingFor,
          onTap: () => setState(() => _lookingFor = 'SERIOUS_COMPANIONSHIP'),
        ),
      ],
    );
  }

  Widget _buildEducationStep() {
    const options = [
      ('High School', 'HIGH_SCHOOL'),
      ("Bachelor's Degree", 'BACHELORS'),
      ("Master's Degree", 'MASTERS'),
      ('Doctorate / PhD', 'DOCTORATE'),
      ('Other', 'OTHER'),
    ];
    return Column(
      children: [
        _stepTitle("What's your highest education?"),
        //_buildIllustration('assets/images/onboarding/education.png'),
        const SizedBox(height: 20),
        for (final (label, value) in options)
          _selectionTile(
            label: label,
            value: value,
            selectedValue: _highestEducation,
            onTap: () => setState(() => _highestEducation = value),
          ),
      ],
    );
  }

  Widget _buildProfessionStep() {
    return Column(
      children: [
        _stepTitle("What do you do for work?"),
        //_buildIllustration('assets/images/onboarding/work.png'),
        const SizedBox(height: 20),
        _inputField(
          controller: _professionCtrl,
          hint: 'e.g. Software Developer, Doctor…',
          capitalization: TextCapitalization.sentences,
          onChanged: (v) => setState(() => _profession = v),
        ),
      ],
    );
  }

  Widget _buildHabitsStep() {
    return Column(
      children: [
        _stepTitle("A few more details"),
        const SizedBox(height: 30),
        _sectionLabel("Do you drink?"),
        Row(
          children: [
            Expanded(
              child: _selectionTile(
                label: 'Yes',
                value: 'YES',
                selectedValue: _drinkingHabit,
                onTap: () => setState(() => _drinkingHabit = 'YES'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectionTile(
                label: 'No',
                value: 'NO',
                selectedValue: _drinkingHabit,
                onTap: () => setState(() => _drinkingHabit = 'NO'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel("Do you smoke?"),
        Row(
          children: [
            Expanded(
              child: _selectionTile(
                label: 'Yes',
                value: 'YES',
                selectedValue: _smokingHabit,
                onTap: () => setState(() => _smokingHabit = 'YES'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectionTile(
                label: 'No',
                value: 'NO',
                selectedValue: _smokingHabit,
                onTap: () => setState(() => _smokingHabit = 'NO'),
              ),
            ),
          ],
        ),
      ],
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
        return _buildLocationStep();
      case 4:
        return _buildEmotionalReadinessStep();
      case 5:
        return _buildLanguagesStep();
      case 6:
        return _buildChildrenStep();
      case 7:
        return _buildHeightStep();
      case 8:
        return _buildLookingForStep();
      case 9:
        return _buildEducationStep();
      case 10:
        return _buildProfessionStep();
      case 11:
        return _buildHabitsStep();
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
            _continueButton(),
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

  // ✅ IMPORTANT: uses Country model
  List<Country> _filtered = _kCountries;

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
                .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
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
              // top drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // title
              Text(
                'Select Country',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              // 🔍 search box
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search your country…',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 📃 country list
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final country = _filtered[i];
                    final isSelected = country.name == widget.selected;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Row(
                        children: [
                          // 🌍 flag
                          CountryFlag.fromCountryCode(
                            country.code,
                            height: 20,
                            width: 28,
                          ),

                          const SizedBox(width: 12),

                          // country name
                          Expanded(
                            child: Text(
                              country.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✔ selected indicator
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,

                      // 👉 select
                      onTap: () => Navigator.pop(context, country.name),
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

class Country {
  final String name;
  final String code;
  const Country(this.name, this.code);
}

const List<Country> _kCountries = [
  Country('India', 'IN'),
  Country('United States', 'US'),
  Country('United Kingdom', 'GB'),
  Country('Canada', 'CA'),
  Country('Australia', 'AU'),
  Country('Germany', 'DE'),
  Country('France', 'FR'),
  Country('Italy', 'IT'),
  Country('Spain', 'ES'),
  Country('Brazil', 'BR'),
];
