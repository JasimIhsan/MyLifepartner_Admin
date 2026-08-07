import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin EditProfileControllerState<T extends StatefulWidget> on State<T> {
  User get user; // Subclasses must provide this from widget

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ProfileRepository profileRepository = ProfileRepository();

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController dateController;
  late TextEditingController emailController;
  late TextEditingController cityController;

  bool isLoading = false;
  bool loadingImage = false;
  String? primaryImageUrl;
  String? country;
  DateTime? dateOfBirth;
  bool isDirty = false;

  @override
  void initState() {
    super.initState();
    dateOfBirth = user.dateOfBirth;
    nameController = TextEditingController(text: user.name ?? '');
    ageController = TextEditingController(text: calculateAge(dateOfBirth));
    dateController = TextEditingController(text: formatDate(dateOfBirth));
    emailController = TextEditingController(text: user.email ?? '');
    cityController = TextEditingController(text: user.city ?? '');
    country = user.country;

    nameController.addListener(checkIfDirty);
    cityController.addListener(checkIfDirty);

    fetchPrimaryImage();
  }

  @override
  void dispose() {
    nameController.removeListener(checkIfDirty);
    cityController.removeListener(checkIfDirty);
    nameController.dispose();
    ageController.dispose();
    dateController.dispose();
    emailController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void checkIfDirty() {
    final dirty = hasUnsavedChanges();
    if (dirty != isDirty) {
      setState(() {
        isDirty = dirty;
      });
    }
  }

  Future<void> fetchPrimaryImage() async {
    if (!mounted) return;
    setState(() => loadingImage = true);
    try {
      final images = await profileRepository.getUserImages();
      if (images.isNotEmpty) {
        final primary = images.firstWhere(
          (img) => img.isPrimary,
          orElse: () => images.first,
        );
        if (mounted) {
          setState(() {
            primaryImageUrl = primary.imageUrl;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching primary image: $e');
    } finally {
      if (mounted) {
        setState(() => loadingImage = false);
      }
    }
  }

  Future<void> navigateToManagePictures() async {
    final result = await context.push(AppRoutes.manageProfilePictures);
    if (result == true) {
      fetchPrimaryImage();
    }
  }

  String formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    return '${value.day}/${value.month}/${value.year}';
  }

  String calculateAge(DateTime? value) {
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

  bool hasUnsavedChanges() {
    final originalName = user.name ?? '';
    final originalCity = user.city ?? '';
    final originalCountry = user.country;
    final originalDob = user.dateOfBirth;

    final isNameChanged = nameController.text.trim() != originalName;
    final isCityChanged = cityController.text.trim() != originalCity;
    final isCountryChanged = country != originalCountry;
    final isDobChanged =
        (dateOfBirth?.year != originalDob?.year) ||
        (dateOfBirth?.month != originalDob?.month) ||
        (dateOfBirth?.day != originalDob?.day);

    return isNameChanged || isCityChanged || isCountryChanged || isDobChanged;
  }

  void showDiscardBottomSheet(BuildContext context) {
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
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Discard Changes?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have unsaved changes. Are you sure you want to discard them?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Keep Editing',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.pop(); // Pop sheet
                        context.pop(); // Pop screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
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

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    if (country == null || country!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your country'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    final age = int.tryParse(ageController.text) ?? 0;
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
      isLoading = true;
    });

    try {
      await profileRepository.updateBasicProfile({
        'name': nameController.text.trim(),
        'country': country,
        'city': cityController.text.trim(),
        'dateOfBirth': dateOfBirth?.toIso8601String(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.black,
          ),
        );
        context.pop(true);
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
          isLoading = false;
        });
      }
    }
  }

  void handleBackPress() {
    if (!isDirty) {
      context.pop();
    } else {
      showDiscardBottomSheet(context);
    }
  }

  Future<void> selectDateOfBirth() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          dateOfBirth != null && dateOfBirth!.isBefore(eighteenYearsAgo)
          ? dateOfBirth!
          : eighteenYearsAgo,
      firstDate: DateTime(1900),
      lastDate: eighteenYearsAgo,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != dateOfBirth) {
      setState(() {
        dateOfBirth = picked;
        dateController.text = formatDate(picked);
        ageController.text = calculateAge(picked);
      });
      checkIfDirty();
    }
  }
}