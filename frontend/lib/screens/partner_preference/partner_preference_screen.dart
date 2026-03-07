import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/questionaire_screen/questionaire_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';

import '../../widgets/multi_select_dialog.dart';

class PartnerPreferenceScreen extends StatefulWidget {
  const PartnerPreferenceScreen({super.key});

  @override
  State<PartnerPreferenceScreen> createState() =>
      _PartnerPreferenceScreenState();
}

class _PartnerPreferenceScreenState extends State<PartnerPreferenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isLoading = false;

  int? _ageFrom;
  int? _ageTo;
  int? _heightFrom;
  int? _heightTo;
  final List<String> _maritalStatus = [];
  List<String> _religion = [];
  List<String> _motherTongue = [];
  List<String> _highestEducation = [];
  List<String> _occupation = [];
  int? _annualIncomeFrom;
  int? _annualIncomeTo;

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

  // Quick multi-select helpers
  void _toggleMaritalStatus(String val) {
    setState(() {
      if (_maritalStatus.contains(val)) {
        _maritalStatus.remove(val);
      } else {
        _maritalStatus.add(val);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_maritalStatus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one marital status'),
        ),
      );
      return;
    }

    if (_ageFrom != null && _ageTo != null && _ageFrom! > _ageTo!) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid age range')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _profileRepo.updatePartnerPreference({
        'ageFrom': _ageFrom,
        'ageTo': _ageTo,
        'heightFrom': _heightFrom,
        'heightTo': _heightTo,
        'maritalStatus': _maritalStatus,
        'religion': _religion,
        'motherTongue': _motherTongue,
        'highestEducation': _highestEducation,
        'occupation': _occupation,
        'annualIncomeFrom': _annualIncomeFrom,
        'annualIncomeTo': _annualIncomeTo,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const QuestionaireScreen()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partner Preferences')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'What are you looking for?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Age Range
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Age From',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null) {
                            return 'Invalid number';
                          }
                          if (parsed < 18 || parsed > 100) {
                            return 'Age 18-100';
                          }
                          return null;
                        },
                        onSaved: (val) =>
                            _ageFrom = (val != null && val.trim().isNotEmpty)
                            ? int.tryParse(val.trim())
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Age To',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null) {
                            return 'Invalid number';
                          }
                          if (parsed < 18 || parsed > 100) {
                            return 'Age 18-100';
                          }
                          return null;
                        },
                        onSaved: (val) =>
                            _ageTo = (val != null && val.trim().isNotEmpty)
                            ? int.tryParse(val.trim())
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Height Range
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Height From (cm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null) {
                            return 'Invalid number';
                          }
                          if (parsed < 50 || parsed > 300) {
                            return 'Height 50-300';
                          }
                          return null;
                        },
                        onSaved: (val) =>
                            _heightFrom = (val != null && val.trim().isNotEmpty)
                            ? int.tryParse(val.trim())
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Height To (cm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null) {
                            return 'Invalid number';
                          }
                          if (parsed < 50 || parsed > 300) {
                            return 'Height 50-300';
                          }
                          return null;
                        },
                        onSaved: (val) =>
                            _heightTo = (val != null && val.trim().isNotEmpty)
                            ? int.tryParse(val.trim())
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Marital Status
                const Text('Marital Status (Select multiple)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children:
                      [
                        'NEVER_MARRIED',
                        'AWATING_DIVORCE',
                        'DIVORCED',
                        'WIDOWED',
                        'ANNULLED',
                      ].map((status) {
                        final isSelected = _maritalStatus.contains(status);
                        return ChoiceChip(
                          label: Text(status.replaceAll('_', ' ')),
                          selected: isSelected,
                          onSelected: (_) => _toggleMaritalStatus(status),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Religion Preferences',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
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
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _religion.isEmpty ? 'Any' : _religion.join(', '),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Mother Tongue Preferences',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
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
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _motherTongue.isEmpty ? 'Any' : _motherTongue.join(', '),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Education Preferences',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
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
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _highestEducation.isEmpty
                          ? 'Any'
                          : _highestEducation.join(', '),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Occupation Preferences',
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
                      _occupation.isEmpty ? 'Any' : _occupation.join(', '),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Annual Income Range
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Annual Income From',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null) {
                            return 'Invalid number';
                          }
                          if (parsed < 0) {
                            return 'Cannot be negative';
                          }
                          return null;
                        },
                        onSaved: (val) => _annualIncomeFrom =
                            (val != null && val.trim().isNotEmpty)
                            ? int.tryParse(val.trim())
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Annual Income To',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return null;
                          }
                          final parsed = int.tryParse(val.trim());
                          if (parsed == null) {
                            return 'Invalid number';
                          }
                          if (parsed < 0) {
                            return 'Cannot be negative';
                          }
                          return null;
                        },
                        onSaved: (val) => _annualIncomeTo =
                            (val != null && val.trim().isNotEmpty)
                            ? int.tryParse(val.trim())
                            : null,
                      ),
                    ),
                  ],
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
