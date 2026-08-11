import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/screens/onboarding/widgets/primay_date_picker.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/services/user_repository.dart';
import 'package:life_partner_again/utils/dio_error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin EditProfileControllerState<T extends StatefulWidget> on State<T> {
  User get user; // Subclasses must provide this from widget

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ProfileRepository profileRepository = ProfileRepository();
  final UserRepository userRepository = UserRepository();

  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController dateController;
  late TextEditingController emailController;
  late TextEditingController cityController;
  late TextEditingController occupationController;
  late TextEditingController bioController;

  bool isLoading = false;
  bool isInitialLoading = true;
  bool loadingImage = false;
  String? primaryImageUrl;
  String? country;
  DateTime? dateOfBirth;
  String? gender;
  String? maritalStatus;
  String? highestEducation;
  String? smokingHabit;
  String? drinkingHabit;
  String? childrenStatus;
  String? lookingFor;
  String? relationshipTimeline;
  List<String> languages = [];
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
    occupationController = TextEditingController(text: user.occupation ?? '');
    bioController = TextEditingController(text: user.bio ?? '');
    country = user.country;
    gender = user.gender;
    maritalStatus = user.maritalStatus;
    highestEducation = user.highestEducation;
    smokingHabit = user.smokingHabit;
    drinkingHabit = user.drinkingHabit;
    childrenStatus = user.childrenStatus;
    lookingFor = user.lookingFor;
    relationshipTimeline = user.relationshipTimeline;
    languages = List.from(user.languages);

    nameController.addListener(checkIfDirty);
    cityController.addListener(checkIfDirty);
    occupationController.addListener(checkIfDirty);
    bioController.addListener(checkIfDirty);

    // Fetch fresh data from backend (seed from widget.user is just a placeholder)
    fetchFreshUserData();
    fetchPrimaryImage();
  }

  @override
  void dispose() {
    nameController.removeListener(checkIfDirty);
    cityController.removeListener(checkIfDirty);
    occupationController.removeListener(checkIfDirty);
    bioController.removeListener(checkIfDirty);
    nameController.dispose();
    ageController.dispose();
    dateController.dispose();
    emailController.dispose();
    cityController.dispose();
    occupationController.dispose();
    bioController.dispose();
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

  /// Fetches fresh user data from the backend and repopulates all form fields.
  Future<void> fetchFreshUserData() async {
    if (!mounted) return;
    setState(() => isInitialLoading = true);
    try {
      final freshUser = await userRepository.getUser();
      if (!mounted) return;
      setState(() {
        // Text controllers
        nameController.text = freshUser.name ?? '';
        emailController.text = freshUser.email ?? '';
        cityController.text = freshUser.city ?? '';
        occupationController.text = freshUser.occupation ?? '';
        bioController.text = freshUser.bio ?? '';

        // Date of birth
        dateOfBirth = freshUser.dateOfBirth;
        dateController.text = formatDate(freshUser.dateOfBirth);
        ageController.text = calculateAge(freshUser.dateOfBirth);

        // Dropdown / picker fields
        country = freshUser.country;
        gender = freshUser.gender;
        maritalStatus = freshUser.maritalStatus;
        highestEducation = freshUser.highestEducation;
        smokingHabit = freshUser.smokingHabit;
        drinkingHabit = freshUser.drinkingHabit;
        childrenStatus = freshUser.childrenStatus;
        lookingFor = freshUser.lookingFor;
        relationshipTimeline = freshUser.relationshipTimeline;
        languages = List.from(freshUser.languages);

        isInitialLoading = false;
        // Reset dirty flag since this is fresh data
        isDirty = false;
      });
    } catch (e) {
      debugPrint('Error fetching fresh user data: $e');
      if (mounted) setState(() => isInitialLoading = false);
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
    final originalOccupation = user.occupation ?? '';
    final originalBio = user.bio ?? '';
    final originalCountry = user.country;
    final originalDob = user.dateOfBirth;

    final isNameChanged = nameController.text.trim() != originalName;
    final isCityChanged = cityController.text.trim() != originalCity;
    final isOccupationChanged =
        occupationController.text.trim() != originalOccupation;
    final isBioChanged = bioController.text.trim() != originalBio;
    final isCountryChanged = country != originalCountry;
    final isGenderChanged = gender != user.gender;
    final isMaritalStatusChanged = maritalStatus != user.maritalStatus;
    final isEducationChanged = highestEducation != user.highestEducation;
    final isSmokingChanged = smokingHabit != user.smokingHabit;
    final isDrinkingChanged = drinkingHabit != user.drinkingHabit;
    final isChildrenStatusChanged = childrenStatus != user.childrenStatus;
    final isLookingForChanged = lookingFor != user.lookingFor;
    final isTimelineChanged = relationshipTimeline != user.relationshipTimeline;

    // Check languages array difference
    final originalLanguages = user.languages.toSet();
    final currentLanguages = languages.toSet();
    final isLanguagesChanged =
        originalLanguages.length != currentLanguages.length ||
        !originalLanguages.containsAll(currentLanguages);

    final isDobChanged =
        (dateOfBirth?.year != originalDob?.year) ||
        (dateOfBirth?.month != originalDob?.month) ||
        (dateOfBirth?.day != originalDob?.day);

    return isNameChanged ||
        isCityChanged ||
        isOccupationChanged ||
        isBioChanged ||
        isCountryChanged ||
        isGenderChanged ||
        isMaritalStatusChanged ||
        isEducationChanged ||
        isSmokingChanged ||
        isDrinkingChanged ||
        isChildrenStatusChanged ||
        isLookingForChanged ||
        isTimelineChanged ||
        isLanguagesChanged ||
        isDobChanged;
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
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have unsaved changes. Are you sure you want to discard them?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
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
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
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
      await profileRepository.updateProfile({
        'name': nameController.text.trim(),
        'country': country,
        'city': cityController.text.trim(),
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'occupation': occupationController.text.trim(),
        'bio': bioController.text.trim(),
        'gender': gender,
        'maritalStatus': maritalStatus,
        'highestEducation': highestEducation,
        'smokingHabit': smokingHabit,
        'drinkingHabit': drinkingHabit,
        'childrenStatus': childrenStatus,
        'lookingFor': lookingFor,
        'relationshipTimeline': relationshipTimeline,
        'languages': languages,
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

    DateTime tempDate =
        (dateOfBirth != null && dateOfBirth!.isBefore(eighteenYearsAgo))
        ? dateOfBirth!
        : eighteenYearsAgo;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: PrimayDatePicker(
            initialDate: tempDate,
            minDate: DateTime(1920, 1, 1),
            maxDate: eighteenYearsAgo,
            onDateChanged: (d) {
              if (d != dateOfBirth) {
                setState(() {
                  dateOfBirth = d;
                  dateController.text = formatDate(d);
                  ageController.text = calculateAge(d);
                });
                checkIfDirty();
              }
            },
          ),
        );
      },
    );
  }
}
