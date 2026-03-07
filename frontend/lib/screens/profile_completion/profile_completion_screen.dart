import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/partner_preference/partner_preference_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_app_bar.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/multi_select_dialog.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isLoading = false;

  String? _name;
  String? _gender;
  DateTime? _dob;
  int? _heightCm;
  String? _maritalStatus;
  List<String> _religion = [];
  List<String> _motherTongue = [];
  String? _city;
  String? _state;
  String? _country;
  List<String> _highestEducation = [];
  List<String> _occupation = [];
  int? _annualIncome;
  String? _bio;

  // Options for predefined multi-select fields:
  final List<String> _religionOptions = [
    'Christianity (Catholic)',
    'Christianity (Protestant)',
    'Christianity (Orthodox)',
    'Islam (Sunni)',
    'Islam (Shia)',
    'Hinduism',
    'Buddhism',
    'Judaism',
    'Sikhism',
    'Jainism',
    'Shinto',
    'Baha\'i',
    'Spiritual',
    'Atheist / Agnostic',
    'No Religion',
    'Other',
  ];
  final List<String> _motherTongueOptions = [
    'English',
    'Spanish',
    'Mandarin Chinese',
    'Arabic',
    'Hindi',
    'Bengali',
    'Portuguese',
    'Russian',
    'Japanese',
    'French',
    'German',
    'Italian',
    'Korean',
    'Vietnamese',
    'Other',
  ];
  final List<String> _educationOptions = [
    'High School / Secondary',
    'Vocational / Diploma',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'Doctorate / PhD',
    'Medical Degree',
    'Law Degree',
    'Other',
  ];
  final List<String> _occupationOptions = [
    'Technology / IT',
    'Healthcare / Medical',
    'Education / Academia',
    'Finance / Business',
    'Law / Legal',
    'Arts / Entertainment',
    'Engineering / Science',
    'Sales / Marketing',
    'Government / Public Service',
    'Manual Labor / Trades',
    'Self-Employed / Entrepreneur',
    'Student',
    'Homemaker',
    'Not Employed',
    'Other',
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_gender == null || _dob == null || _maritalStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _profileRepo.updateBasicProfile({
        'name': _name,
        'gender': _gender,
        'dateOfBirth': _dob != null ? '${_dob!.toIso8601String()}Z' : null,
        'heightCm': _heightCm,
        'maritalStatus': _maritalStatus,
        'religion': _religion.isEmpty ? null : _religion.join(', '),
        'motherTongue': _motherTongue.isEmpty ? null : _motherTongue.join(', '),
        'city': _city,
        'state': _state,
        'country': _country,
        'highestEducation': _highestEducation.isEmpty
            ? null
            : _highestEducation.join(', '),
        'occupation': _occupation.isEmpty ? null : _occupation.join(', '),
        'annualIncome': _annualIncome,
        'bio': _bio,
      });

      final sharedPrefs = await SharedPreferences.getInstance();
      if (_name != null) {
        await sharedPrefs.setString('name', _name!);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PartnerPreferenceScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null && picked != _dob) {
      setState(() {
        _dob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        leading: null,
        title: 'Basic Details',
        actions: [
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final sharedPrefs = await SharedPreferences.getInstance();
              await sharedPrefs.clear();
              if (mounted) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Icon(Icons.logout, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Tell us about yourself',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  onSaved: (val) => _name = val,
                ),
                const SizedBox(height: 16),

                // Gender
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (val) => setState(() => _gender = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // DOB
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth *',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _dob == null
                          ? 'Select Date'
                          : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Height
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Height (cm) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Required';
                    }
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null) {
                      return 'Must be a valid number';
                    }
                    if (parsed < 50 || parsed > 300) {
                      return 'Height must be between 50cm and 300cm';
                    }
                    return null;
                  },
                  onSaved: (val) => _heightCm = int.tryParse(val!.trim()),
                ),
                const SizedBox(height: 16),

                // Marital Status
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Marital Status *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'NEVER_MARRIED',
                      child: Text('Never Married'),
                    ),
                    DropdownMenuItem(
                      value: 'AWATING_DIVORCE',
                      child: Text('Awaiting Divorce'),
                    ),
                    DropdownMenuItem(
                      value: 'DIVORCED',
                      child: Text('Divorced'),
                    ),
                    DropdownMenuItem(value: 'WIDOWED', child: Text('Widowed')),
                    DropdownMenuItem(
                      value: 'ANNULLED',
                      child: Text('Annulled'),
                    ),
                  ],
                  onChanged: (val) => setState(() => _maritalStatus = val),
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Religion
                const Text(
                  'Religion *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FormField<List<String>>(
                  initialValue: _religion,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  builder: (FormFieldState<List<String>> state) {
                    return InkWell(
                      onTap: () async {
                        final result = await showDialog<List<String>>(
                          context: context,
                          builder: (ctx) => MultiSelectDialog(
                            options: _religionOptions,
                            selectedOptions: _religion,
                            title: 'Select Religion',
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _religion = result;
                          });
                          state.didChange(result);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          errorText: state.errorText,
                        ),
                        child: Text(
                          _religion.isEmpty
                              ? 'Select Religion'
                              : _religion.join(', '),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Mother Tongue
                const Text(
                  'Mother Tongue *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FormField<List<String>>(
                  initialValue: _motherTongue,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  builder: (FormFieldState<List<String>> state) {
                    return InkWell(
                      onTap: () async {
                        final result = await showDialog<List<String>>(
                          context: context,
                          builder: (ctx) => MultiSelectDialog(
                            options: _motherTongueOptions,
                            selectedOptions: _motherTongue,
                            title: 'Select Mother Tongue',
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _motherTongue = result;
                          });
                          state.didChange(result);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          errorText: state.errorText,
                        ),
                        child: Text(
                          _motherTongue.isEmpty
                              ? 'Select Mother Tongue'
                              : _motherTongue.join(', '),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Location Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Required'
                            : null,
                        onSaved: (val) => _city = val?.trim(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'State *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Required'
                            : null,
                        onSaved: (val) => _state = val?.trim(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Country
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Country *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                  onSaved: (val) => _country = val?.trim(),
                ),
                const SizedBox(height: 16),

                // Education
                const Text(
                  'Highest Education *',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                FormField<List<String>>(
                  initialValue: _highestEducation,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                  builder: (FormFieldState<List<String>> state) {
                    return InkWell(
                      onTap: () async {
                        final result = await showDialog<List<String>>(
                          context: context,
                          builder: (ctx) => MultiSelectDialog(
                            options: _educationOptions,
                            selectedOptions: _highestEducation,
                            title: 'Select Education',
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            _highestEducation = result;
                          });
                          state.didChange(result);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          errorText: state.errorText,
                        ),
                        child: Text(
                          _highestEducation.isEmpty
                              ? 'Select Education'
                              : _highestEducation.join(', '),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Occupation
                const Text(
                  'Occupation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final result = await showDialog<List<String>>(
                      context: context,
                      builder: (ctx) => MultiSelectDialog(
                        options: _occupationOptions,
                        selectedOptions: _occupation,
                        title: 'Select Occupation',
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _occupation = result;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _occupation.isEmpty
                          ? 'Select Occupation'
                          : _occupation.join(', '),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Annual Income
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Annual Income',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return null; // Optional field, but validated if present
                    }
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null) {
                      return 'Must be a valid number';
                    }
                    if (parsed < 0) {
                      return 'Income cannot be negative';
                    }
                    return null;
                  },
                  onSaved: (val) =>
                      _annualIncome = (val != null && val.trim().isNotEmpty)
                      ? int.tryParse(val.trim())
                      : null,
                ),
                const SizedBox(height: 16),

                // Bio
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Bio (min 50 characters) *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4, // giving them a bit more space to write
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Required';
                    }
                    if (val.trim().length < 50) {
                      return 'Bio must be at least 50 characters';
                    }
                    return null;
                  },
                  onSaved: (val) => _bio = val?.trim(),
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Save and Continue',
                  isLoading: _isLoading,
                  onPressed: _submit,
                  backgroundColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
