import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/screens/profile_screen/manage_profile_pictures_screen.dart';
import 'package:life_partner_again/screens/profile_screen/widgets/edit_profile_ui_helpers.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/widgets/header_waves_background.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
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
  bool _loadingImage = false;
  String? _primaryImageUrl;
  String? _country;
  DateTime? _dateOfBirth;
  bool _isDirty = false;

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

    _nameController.addListener(_checkIfDirty);
    _cityController.addListener(_checkIfDirty);

    _fetchPrimaryImage();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.removeListener(_checkIfDirty);
    _cityController.removeListener(_checkIfDirty);
    _nameController.dispose();
    _ageController.dispose();
    _dateController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _checkIfDirty() {
    final dirty = _hasUnsavedChanges();
    if (dirty != _isDirty) {
      setState(() {
        _isDirty = dirty;
      });
    }
  }

  Future<void> _fetchPrimaryImage() async {
    if (!mounted) return;
    setState(() => _loadingImage = true);
    try {
      final images = await _profileRepository.getUserImages();
      if (images.isNotEmpty) {
        final primary = images.firstWhere(
          (img) => img.isPrimary,
          orElse: () => images.first,
        );
        if (mounted) {
          setState(() {
            _primaryImageUrl = primary.imageUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching primary image: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingImage = false);
      }
    }
  }

  Future<void> _navigateToManagePictures() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManageProfilePicturesScreen(),
      ),
    );
    if (result == true) {
      _fetchPrimaryImage();
    }
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

  bool _hasUnsavedChanges() {
    final originalName = widget.user.name ?? '';
    final originalCity = widget.user.city ?? '';
    final originalCountry = widget.user.country;
    final originalDob = widget.user.dateOfBirth;

    final isNameChanged = _nameController.text.trim() != originalName;
    final isCityChanged = _cityController.text.trim() != originalCity;
    final isCountryChanged = _country != originalCountry;
    final isDobChanged =
        (_dateOfBirth?.year != originalDob?.year) ||
        (_dateOfBirth?.month != originalDob?.month) ||
        (_dateOfBirth?.day != originalDob?.day);

    return isNameChanged || isCityChanged || isCountryChanged || isDobChanged;
  }

  void _showDiscardBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Discard Changes?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You have unsaved changes. Are you sure you want to discard them?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Keep Editing',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Pop sheet
                        Navigator.pop(context); // Pop screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Discard',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showDiscardBottomSheet(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFD),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      // Header waves background painted with Flutter
                      const HeaderWavesBackground(),

                      Column(
                        children: [
                          // App Bar Row
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 8,
                              left: 8,
                              right: 8,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                      final shouldPop = !_isDirty;
                                      if (shouldPop) {
                                        Navigator.pop(context);
                                      } else {
                                        _showDiscardBottomSheet(context);
                                      }
                                    },
                                  ),
                                ),
                                const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Avatar Section
                          GestureDetector(
                            onTap: _navigateToManagePictures,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: Colors.grey[100],
                                    backgroundImage:
                                        _primaryImageUrl != null &&
                                            _primaryImageUrl!.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            _primaryImageUrl!,
                                          )
                                        : null,
                                    child: _loadingImage
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : (_primaryImageUrl == null ||
                                                  _primaryImageUrl!.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 54,
                                                  color: Colors.grey,
                                                )
                                              : null),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // User Info
                          Text(
                            widget.user.name ?? '',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email ?? '',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Floating Rounded Card
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 20,
                              ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 24,
                                  bottom:
                                      MediaQuery.of(context).padding.bottom > 0
                                      ? MediaQuery.of(context).padding.bottom
                                      : 24,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Section Header: Personal Details
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.person_outline_rounded,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'PERSONAL DETAILS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      MinimalTextField(
                                        controller: _nameController,
                                        label: 'Display Name',
                                        hintText: 'Enter your name',
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),

                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: MinimalTextField(
                                              controller: _dateController,
                                              label: 'Date of Birth',
                                              hintText: 'Select date',
                                              readOnly: true,
                                              onTap: () async {
                                                final now = DateTime.now();
                                                final eighteenYearsAgo =
                                                    DateTime(
                                                      now.year - 18,
                                                      now.month,
                                                      now.day,
                                                    );
                                                final DateTime?
                                                picked = await showDatePicker(
                                                  context: context,
                                                  initialDate:
                                                      _dateOfBirth != null &&
                                                          _dateOfBirth!.isBefore(
                                                            eighteenYearsAgo,
                                                          )
                                                      ? _dateOfBirth!
                                                      : eighteenYearsAgo,
                                                  firstDate: DateTime(1900),
                                                  lastDate: eighteenYearsAgo,
                                                  builder: (context, child) {
                                                    return Theme(
                                                      data: Theme.of(context).copyWith(
                                                        colorScheme:
                                                            const ColorScheme.light(
                                                              primary: AppColors
                                                                  .primary,
                                                              onPrimary:
                                                                  Colors.white,
                                                              onSurface: AppColors
                                                                  .textPrimary,
                                                            ),
                                                      ),
                                                      child: child!,
                                                    );
                                                  },
                                                );
                                                if (picked != null &&
                                                    picked != _dateOfBirth) {
                                                  setState(() {
                                                    _dateOfBirth = picked;
                                                    _dateController.text =
                                                        _formatDate(picked);
                                                    _ageController.text =
                                                        _calculateAge(picked);
                                                  });
                                                  _checkIfDirty();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: MinimalTextField(
                                              controller: _ageController,
                                              label: 'Calculated Age',
                                              hintText: '--',
                                              enabled: false,
                                              readOnly: true,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),

                                      // Section Header: Location Information
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'LOCATION SETTINGS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      MinimalCountryPicker(
                                        country: _country,
                                        onChanged: (val) {
                                          setState(() {
                                            _country = val;
                                          });
                                          _checkIfDirty();
                                        },
                                      ),

                                      MinimalTextField(
                                        controller: _cityController,
                                        label: 'City',
                                        hintText: 'Enter city name',
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your city';
                                          }
                                          return null;
                                        },
                                      ),
                                      const Spacer(),
                                      const SizedBox(height: 24),

                                      // Save Button Container at the very bottom
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: (_isDirty && !_isLoading)
                                              ? _saveProfile
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: AppColors
                                                .primary
                                                .withValues(alpha: 0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.save_outlined,
                                                      color: Colors.white,
                                                      size: 22,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      width: 1,
                                                      height: 20,
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Text(
                                                      'Save Changes',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Minimal Custom Inputs ──────────────────────────────────────────────────

class MinimalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const MinimalTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            onTap: onTap,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: enabled ? AppColors.textPrimary : AppColors.textLight,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              disabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.error, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MinimalReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final String lockedReason;

  const MinimalReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.lockedReason,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.textLight,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lockedReason,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textLight,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
        ],
      ),
    );
  }
}

class MinimalCountryPicker extends StatelessWidget {
  final String? country;
  final ValueChanged<String> onChanged;

  const MinimalCountryPicker({
    super.key,
    required this.country,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasCountry = country != null && country!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          final selected = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => EditProfileCountryPickerSheet(selected: country),
          );

          if (selected != null) {
            onChanged(selected);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Country',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasCountry ? country! : 'Select your country',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasCountry
                        ? AppColors.textPrimary
                        : AppColors.textLight,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textLight,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
          ],
        ),
      ),
    );
  }
}

// ─── Custom Painters ────────────────────────────────────────────────────────

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFFE2ECF7)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        canvas.drawCircle(Offset(i * 8.0, j * 8.0), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
