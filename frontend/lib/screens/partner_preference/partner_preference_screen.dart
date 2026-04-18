import 'package:flutter/material.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Total steps updated to 6 to match the active steps
  static const int _totalSteps = 6;

  // Data
  RangeValues _ageRange = const RangeValues(25, 45);
  RangeValues _heightRange = const RangeValues(150, 185);
  final List<String> _maritalStatus = [];
  final List<String> _education = [];
  final List<String> _occupation = [];
  final List<String> _languages = [];

  bool get _isCurrentStepValid {
    switch (_currentStep) {
      case 1:
        return _maritalStatus.isNotEmpty;
      case 2:
        return _education.isNotEmpty;
      case 3:
        return _occupation.isNotEmpty;
      case 4:
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
      await _profileRepo.updatePartnerPreference({
        'ageFrom': _ageRange.start.round(),
        'ageTo': _ageRange.end.round(),
        'heightFrom': _heightRange.start.round(),
        'heightTo': _heightRange.end.round(),
        // 'annualIncomeFrom': _incomeRange.start.round(),
        // 'annualIncomeTo': _incomeRange.end.round(),
        'maritalStatus': _maritalStatus,
        'highestEducation': _education,
        'occupation': _occupation,
        // 'religion': _religion,
        'motherTongue': _languages,
      });

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

  Widget _buildIllustration(String assetPath, {double height = 160}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Image.asset(
          assetPath,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (ctx, _, __) => Container(
            height: height,
            width: height * 1.5,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _stepHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
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
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip(
    String label,
    String value,
    List<String> selected,
    VoidCallback onTap,
  ) {
    final isSelected = selected.contains(value);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _toggle(List<String> list, String value) {
    setState(() {
      list.contains(value) ? list.remove(value) : list.add(value);
    });
  }

  // ─── Steps ────────────────────────────────────────────────────────────────

  Widget _buildAgeStep() {
    return _PrefStepContainer(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "What age range are you looking for?",
            subtitle: "Drag the slider to set your preference.",
          ),
          //_buildIllustration('assets/images/onboarding/relationship.png'),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _labelWithSuffix('From', _ageRange.start.round(), 'yrs'),
                _labelWithSuffix('To', _ageRange.end.round(), 'yrs'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _customRangeSlider(
            values: _ageRange,
            min: 18,
            max: 80,
            divisions: 62,
            onChanged: (v) => setState(() => _ageRange = v),
          ),
        ],
      ),
    );
  }

  Widget _buildMaritalStep() {
    const options = [
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Annulled', 'ANNULLED'),
      ('Legally Separated', 'LEGALLY_SEPARATED'),
      ('Awaiting Divorce', 'AWATING_DIVORCE'),
    ];
    return _PrefStepContainer(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "Which background are you open to?",
            subtitle: "Select at least one option.",
          ),
          //_buildIllustration('assets/images/onboarding/marital_status.png'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map(
                  (o) => _chip(
                    o.$1,
                    o.$2,
                    _maritalStatus,
                    () => _toggle(_maritalStatus, o.$2),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationStep() {
    const options = [
      ('High School', 'HIGH_SCHOOL'),
      ('Vocational / Diploma', 'VOCATIONAL'),
      ("Bachelor's", 'BACHELORS'),
      ("Master's", 'MASTERS'),
      ('Doctorate / PhD', 'DOCTORATE'),
      ('Medical Degree', 'MEDICAL'),
      ('Law Degree', 'LAW'),
      ('Other', 'OTHER'),
    ];
    return _PrefStepContainer(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "What education level do you prefer?",
            subtitle: "Select at least one option.",
          ),
          //_buildIllustration('assets/images/onboarding/education.png'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map(
                  (o) => _chip(
                    o.$1,
                    o.$2,
                    _education,
                    () => _toggle(_education, o.$2),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupationStep() {
    const options = [
      ('Technology / IT', 'Technology / IT'),
      ('Healthcare', 'Healthcare / Medical'),
      ('Education', 'Education / Academia'),
      ('Finance', 'Finance / Business'),
      ('Law / Legal', 'Law / Legal'),
      ('Arts / Creative', 'Arts / Entertainment'),
      ('Engineering', 'Engineering / Science'),
      ('Sales / Marketing', 'Sales / Marketing'),
      ('Government', 'Government / Public Service'),
      ('Trades', 'Manual Labor / Trades'),
      ('Entrepreneur', 'Self-Employed / Entrepreneur'),
      ('Other', 'Other'),
    ];
    return _PrefStepContainer(
      key: const ValueKey(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "Any industry preference?",
            subtitle: "Select at least one option.",
          ),
          //_buildIllustration('assets/images/onboarding/work.png'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map(
                  (o) => _chip(
                    o.$1,
                    o.$2,
                    _occupation,
                    () => _toggle(_occupation, o.$2),
                  ),
                )
                .toList(),
          ),
        ],
      ),
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
    return _PrefStepContainer(
      key: const ValueKey(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "Any language preference?",
            subtitle: "Select at least one option.",
          ),
          //_buildIllustration('assets/images/onboarding/language_female.png'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: langs
                .map(
                  (l) => _chip(l, l, _languages, () => _toggle(_languages, l)),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // Widget _buildReligionStep() {
  //   const options = [
  //     'Islam',
  //     'Hinduism',
  //     'Christianity',
  //     'Sikhism',
  //     'Buddhism',
  //     'Jainism',
  //     'Other',
  //   ];
  //   return _PrefStepContainer(
  //     key: const ValueKey(5),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _stepHeader(
  //           "What is your religious preference?",
  //           subtitle: "Select at least one option.",
  //         ),
  //         const SizedBox(height: 32),
  //         Wrap(
  //           spacing: 10,
  //           runSpacing: 10,
  //           children: options
  //               .map((r) => _chip(r, r, _religion, () => _toggle(_religion, r)))
  //               .toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildHeightStep() {
    return _PrefStepContainer(
      key: const ValueKey(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "What height range do you prefer?",
            subtitle: "Drag the slider to set your preference.",
          ),
          //_buildIllustration(
          //  'assets/images/onboarding/height_female.png',
          // height: 140,
          //),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _labelWithSuffix('Min', _heightRange.start.round(), 'cm'),
                _labelWithSuffix('Max', _heightRange.end.round(), 'cm'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _customRangeSlider(
            values: _heightRange,
            min: 120,
            max: 220,
            divisions: 100,
            onChanged: (v) => setState(() => _heightRange = v),
          ),
        ],
      ),
    );
  }

  // Widget _buildIncomeStep() {
  //   return _PrefStepContainer(
  //     key: const ValueKey(7),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _stepHeader(
  //           "Any annual income preference?",
  //           subtitle: "Values are in Lakhs per annum.",
  //         ),
  //         const SizedBox(height: 48),
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 4),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               _labelWithSuffix('Min', _incomeRange.start.round(), 'L'),
  //               _labelWithSuffix('Max', _incomeRange.end.round(), 'L'),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 20),
  //         _customRangeSlider(
  //           values: _incomeRange,
  //           min: 0,
  //           max: 200,
  //           divisions: 40,
  //           onChanged: (v) => setState(() => _incomeRange = v),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _labelWithSuffix(String label, int value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 2),
        Text(
          '$value $suffix',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _customRangeSlider({
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.borderColor,
        thumbColor: AppColors.primary,
        rangeThumbShape: const RoundRangeSliderThumbShape(
          enabledThumbRadius: 10,
        ),
        overlayColor: AppColors.primary,
      ),
      child: RangeSlider(
        values: values,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildAgeStep();
      case 1:
        return _buildMaritalStep();
      case 2:
        return _buildEducationStep();
      case 3:
        return _buildOccupationStep();
      case 4:
        return _buildLanguagesStep();
      // case 5:
      //   return _buildReligionStep();
      case 5:
        return _buildHeightStep();
      // case 6:
      //   return _buildIncomeStep();
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
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: _back,
              )
            : const SizedBox.shrink(),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / _totalSteps,
                backgroundColor: AppColors.borderColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 4,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
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
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _buildCurrentStep(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_isCurrentStepValid)
                      ? null
                      : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.borderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'Finish'
                              : 'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

class _PrefStepContainer extends StatelessWidget {
  final Widget child;
  const _PrefStepContainer({required super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: child,
    );
  }
}
