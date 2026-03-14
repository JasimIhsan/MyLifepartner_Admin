import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PartnerPreferenceScreen extends StatefulWidget {
  const PartnerPreferenceScreen({super.key});

  @override
  State<PartnerPreferenceScreen> createState() =>
      _PartnerPreferenceScreenState();
}

class _PartnerPreferenceScreenState
    extends State<PartnerPreferenceScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isLoading = false;
  int _currentStep = 0;
  bool _goingForward = true;

  // Step 0 : Age range
  // Step 1 : Marital status open to
  // Step 2 : Education preference
  // Step 3 : Occupation / industry preference
  // Step 4 : Languages preference
  static const int _totalSteps = 5;

  // Data
  RangeValues _ageRange = const RangeValues(25, 45);
  final List<String> _maritalStatus = [];
  final List<String> _education = [];
  final List<String> _occupation = [];
  final List<String> _languages = [];

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
        'maritalStatus': _maritalStatus,
        'highestEducation': _education,
        'occupation': _occupation,
        'motherTongue': _languages, // reused as languages
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedPartnerPreference', true);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll('Exception: ', '')),
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

  // Pill chip — used for multi-select lists
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
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
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

  // Step 0 — Age range
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
          const SizedBox(height: 48),

          // Age labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ageLabel('From', _ageRange.start.round()),
                _ageLabel('To', _ageRange.end.round()),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.borderColor,
              thumbColor: AppColors.primary,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 22),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: RangeSlider(
              values: _ageRange,
              min: 18,
              max: 80,
              divisions: 62,
              onChanged: (v) => setState(() => _ageRange = v),
            ),
          ),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('18',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
              Text('80',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ageLabel(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '$value yrs',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Step 1 — Marital status
  Widget _buildMaritalStep() {
    const options = [
      ('Never Married', 'NEVER_MARRIED'),
      ('Divorced', 'DIVORCED'),
      ('Widowed', 'WIDOWED'),
      ('Legally Separated', 'LEGALLY_SEPARATED'),
    ];
    return _PrefStepContainer(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "Which background are you open to?",
            subtitle: "Select all that apply. Leave blank for any.",
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map((o) => _chip(o.$1, o.$2, _maritalStatus,
                    () => _toggle(_maritalStatus, o.$2)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Step 2 — Education
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
            subtitle: "Leave blank to be open to all.",
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map((o) => _chip(o.$1, o.$2, _education,
                    () => _toggle(_education, o.$2)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Step 3 — Occupation
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
            subtitle: "Leave blank to be open to all.",
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map((o) => _chip(o.$1, o.$2, _occupation,
                    () => _toggle(_occupation, o.$2)))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Step 4 — Languages
  Widget _buildLanguagesStep() {
    const langs = [
      'English', 'Arabic', 'Hindi', 'Urdu', 'Bengali',
      'Mandarin', 'Spanish', 'French', 'Portuguese', 'Russian',
      'German', 'Japanese', 'Korean', 'Turkish', 'Italian',
      'Malay', 'Swahili', 'Punjabi', 'Tamil', 'Other',
    ];
    return _PrefStepContainer(
      key: const ValueKey(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            "Any language preference?",
            subtitle: "Leave blank to be open to all.",
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: langs
                .map((l) => _chip(
                    l, l, _languages, () => _toggle(_languages, l)))
                .toList(),
          ),
        ],
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

            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderColor,
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

// ── Step container ────────────────────────────────────────────────────────────
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
