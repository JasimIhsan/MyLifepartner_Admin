import 'package:mylifepartner/screens/profile_screen/widgets/edit_profile_ui_helpers.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/auth_response.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final ProfileRepository _profileRepository = ProfileRepository();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _dateController;
  late TextEditingController _emailController;
  late TextEditingController _cityController;

  bool _isLoading = false;
  String? _country;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dateOfBirth = widget.user.dateOfBirth;
    _nameController = TextEditingController(text: widget.user.name ?? '');
    _ageController = TextEditingController(text: _calculateAge(_dateOfBirth));
    _dateController = TextEditingController(text: _formatDate(_dateOfBirth));
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _country = widget.user.country;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _ageController.dispose();
    _dateController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    return '${value.day}/${value.month}/${value.year}';
  }

  String _calculateAge(DateTime? value) {
    if (value == null) {
      return '';
    }

    final now = DateTime.now();
    int age = now.year - value.year;
    final hadBirthdayThisYear =
        now.month > value.month ||
        (now.month == value.month && now.day >= value.day);
    if (!hadBirthdayThisYear) {
      age--;
    }

    return age.toString();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_country == null || _country!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your country'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    final age = int.tryParse(_ageController.text) ?? 0;
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be at least 18 years old'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _profileRepository.updateBasicProfile({
        'name': _nameController.text.trim(),
        'country': _country,
        'city': _cityController.text.trim(),
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', _nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.black,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile';
        if (e is DioException) {
          errorMessage = getDioErrorMessage(e, fallback: errorMessage);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.black),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profile Info',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome / Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.mode_edit_outline_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Keep Your Profile Fresh',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Provide accurate information so matches can find you easily.',
                      style: TextStyle(
                        color: AppColors.textWhite.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Section 1: Account Info
              EditProfileSection(
                title: 'Account Credentials',
                icon: Icons.lock_open_rounded,
                children: [
                  EditProfileReadOnlyField(
                    label: 'Email Address',
                    value: _emailController.text,
                    icon: Icons.email_outlined,
                    lockedReason: 'This email is linked to your registered login.',
                  ),
                ],
              ),

              // Section 2: Personal Profile
              EditProfileSection(
                title: 'Personal Details',
                icon: Icons.person_outline_rounded,
                children: [
                  EditProfileLabel(text: 'Display Name'),
                  const SizedBox(height: 8),
                  EditProfileTextField(
                    controller: _nameController,
                    hintText: 'Enter your name',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EditProfileLabel(text: 'Date of Birth'),
                            const SizedBox(height: 8),
                            EditProfileTextField(
                              controller: _dateController,
                              hintText: 'Date of birth',
                              prefixIcon: Icons.calendar_month_outlined,
                              readOnly: true,
                              onTap: () async {
                                final now = DateTime.now();
                                final eighteenYearsAgo =
                                    DateTime(now.year - 18, now.month, now.day);
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfBirth != null &&
                                          _dateOfBirth!
                                              .isBefore(eighteenYearsAgo)
                                      ? _dateOfBirth!
                                      : eighteenYearsAgo,
                                  firstDate: DateTime(1900),
                                  lastDate: eighteenYearsAgo,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: AppColors.primary,
                                          onPrimary: Colors.white,
                                          onSurface: AppColors.textPrimary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null && picked != _dateOfBirth) {
                                  setState(() {
                                    _dateOfBirth = picked;
                                    _dateController.text = _formatDate(picked);
                                    _ageController.text = _calculateAge(picked);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EditProfileLabel(text: 'Calculated Age'),
                            const SizedBox(height: 8),
                            EditProfileTextField(
                              controller: _ageController,
                              hintText: '--',
                              prefixIcon: Icons.cake_outlined,
                              enabled: false,
                              suffixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Section 3: Location Settings
              EditProfileSection(
                title: 'Location Information',
                icon: Icons.location_on_outlined,
                children: [
                  EditProfileLabel(text: 'Country'),
                  const SizedBox(height: 8),
                  EditProfileCountryPicker(
                    country: _country,
                    onChanged: (val) {
                      setState(() {
                        _country = val;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  EditProfileLabel(text: 'City'),
                  const SizedBox(height: 8),
                  EditProfileTextField(
                    controller: _cityController,
                    hintText: 'Enter your city',
                    prefixIcon: Icons.location_city_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your city';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Save Button Container
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Save Changes',
                  onPressed: _saveProfile,
                  isLoading: _isLoading,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

}
