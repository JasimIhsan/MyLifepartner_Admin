import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/screens/onboarding/widgets/basic_info_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/bio_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/children_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/education_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/emotional_readiness_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/gender_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/habits_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/height_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/languages_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/location_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/looking_for_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/marital_status_step.dart';
import 'package:life_partner_again/screens/onboarding/widgets/profession_step.dart';
import 'package:life_partner_again/services/job_service.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin OnboardingControllerState<T extends StatefulWidget> on State<T> {
  final ProfileRepository profileRepo = ProfileRepository();
  final int totalSteps = 13;
  int currentStep = 0;
  bool isLoading = false;
  bool goingForward = true;

  // Form controllers
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController bioCtrl = TextEditingController();
  final TextEditingController countryCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController heightCtrl = TextEditingController();
  final TextEditingController professionCtrl = TextEditingController();

  // Selected values
  String? firstName;
  String? lastName;
  DateTime? dateOfBirth;
  String? bio;
  String? gender;
  String? country;
  String? city;
  int? heightCm;
  String? maritalStatus;
  String? childrenStatus;
  String? emotionalReadiness;
  String? lookingFor;
  String? relationshipTimeline;
  String? highestEducation;
  String? profession;
  int? jobId;
  final List<String> languages = [];
  String? smokingHabit;
  String? drinkingHabit;

  @override
  void initState() {
    super.initState();
    loadCachedData();
  }

  Future<void> loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('onboarding_first_name');
      lastName = prefs.getString('onboarding_last_name');
      firstNameCtrl.text = firstName ?? '';
      lastNameCtrl.text = lastName ?? '';

      final dobStr = prefs.getString('onboarding_date_of_birth');
      if (dobStr != null) {
        dateOfBirth = DateTime.tryParse(dobStr);
      }

      bio = prefs.getString('onboarding_bio');
      bioCtrl.text = bio ?? '';

      gender = prefs.getString('onboarding_gender');
      country = prefs.getString('onboarding_country');
      countryCtrl.text = country ?? '';

      city = prefs.getString('onboarding_city');
      cityCtrl.text = city ?? '';

      heightCm = prefs.getInt('onboarding_height_cm');
      if (heightCm != null) {
        heightCtrl.text = heightCm.toString();
      }

      maritalStatus = prefs.getString('onboarding_marital_status');
      childrenStatus = prefs.getString('onboarding_children_status');
      emotionalReadiness = prefs.getString('onboarding_emotional_readiness');
      lookingFor = prefs.getString('onboarding_looking_for');
      highestEducation = prefs.getString('onboarding_highest_education');

      profession = prefs.getString('onboarding_profession');
      professionCtrl.text = profession ?? '';
      jobId = prefs.getInt('onboarding_job_id');

      final langs = prefs.getStringList('onboarding_languages');
      if (langs != null) {
        languages.clear();
        languages.addAll(langs);
      }

      smokingHabit = prefs.getString('onboarding_smoking_habit');
      drinkingHabit = prefs.getString('onboarding_drinking_habit');

      final cachedStep = prefs.getInt('onboarding_current_step') ?? 0;
      if (cachedStep >= totalSteps) {
        currentStep = totalSteps - 1;
      } else if (cachedStep < 0) {
        currentStep = 0;
      } else {
        currentStep = cachedStep;
      }
    });
  }

  Future<void> saveToCache(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  Future<void> clearCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'onboarding_first_name',
      'onboarding_last_name',
      'onboarding_date_of_birth',
      'onboarding_bio',
      'onboarding_gender',
      'onboarding_country',
      'onboarding_city',
      'onboarding_height_cm',
      'onboarding_marital_status',
      'onboarding_children_status',
      'onboarding_emotional_readiness',
      'onboarding_looking_for',
      'onboarding_highest_education',
      'onboarding_profession',
      'onboarding_job_id',
      'onboarding_languages',
      'onboarding_smoking_habit',
      'onboarding_drinking_habit',
      'onboarding_current_step',
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    bioCtrl.dispose();
    countryCtrl.dispose();
    cityCtrl.dispose();
    heightCtrl.dispose();
    professionCtrl.dispose();
    super.dispose();
  }

  bool get canProceed {
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\']+$");
    final professionRegex = RegExp(r"^[a-zA-Z0-9\s\-\'\.\,]+$");

    switch (currentStep) {
      case 0:
        if (firstName == null || !nameRegex.hasMatch(firstName!.trim())) {
          return false;
        }
        if (lastName == null || !nameRegex.hasMatch(lastName!.trim())) {
          return false;
        }
        if (dateOfBirth == null) return false;
        final today = DateTime.now();
        int age = today.year - dateOfBirth!.year;
        if (today.month < dateOfBirth!.month ||
            (today.month == dateOfBirth!.month &&
                today.day < dateOfBirth!.day)) {
          age--;
        }
        return age >= 18;
      case 1:
        return bio == null || bio!.trim().isEmpty || bio!.trim().length >= 50;
      case 2:
        return gender != null;
      case 3:
        return maritalStatus != null;
      case 4:
        if (!mounted) return false;
        final locProvider = context.read<LocationProvider>();
        return locProvider.selectedCountry != null &&
            locProvider.selectedCity != null;
      case 5:
        return emotionalReadiness != null;
      case 6:
        return languages.isNotEmpty;
      case 7:
        return childrenStatus != null;
      case 8:
        return heightCm != null;
      case 9:
        return lookingFor != null;
      case 10:
        return highestEducation != null;
      case 11:
        return profession != null &&
            professionRegex.hasMatch(profession!.trim());
      case 12:
        return smokingHabit != null && drinkingHabit != null;
      default:
        return true;
    }
  }

  void next() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        goingForward = true;
        currentStep++;
      });
      saveToCache('onboarding_current_step', currentStep);
    } else {
      submit();
    }
  }

  void back() {
    if (currentStep > 0) {
      setState(() {
        goingForward = false;
        currentStep--;
      });
      saveToCache('onboarding_current_step', currentStep);
    }
  }

  Future<void> submit() async {
    setState(() => isLoading = true);
    try {
      final name = '${firstName?.trim() ?? ""} ${lastName?.trim() ?? ""}'
          .trim();

      int? localJobId = jobId;
      if (localJobId == null &&
          profession != null &&
          profession!.trim().isNotEmpty) {
        try {
          final newJob = await JobService.createJob(profession!);
          localJobId = newJob.id;
        } catch (_) {}
      }

      if (!mounted) return;
      final locProvider = context.read<LocationProvider>();

      await profileRepo.updateBasicProfile({
        'name': name,
        'bio': bio,
        'gender': gender,
        'dateOfBirth': dateOfBirth != null
            ? '${dateOfBirth!.toIso8601String()}Z'
            : null,
        'country': locProvider.selectedCountry?.name ?? country,
        'city': locProvider.selectedCity?.name ?? city,
        'state': locProvider.selectedState?.name,
        'heightCm': heightCm,
        'maritalStatus': maritalStatus,
        'childrenStatus': childrenStatus,
        'emotionalReadiness': emotionalReadiness,
        'lookingFor': lookingFor,
        'relationshipTimeline': relationshipTimeline,
        'highestEducation': highestEducation,
        'occupation': profession,
        'jobId': localJobId,
        'languages': languages,
        'smokingHabit': smokingHabit,
        'drinkingHabit': drinkingHabit,
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await clearCachedData();

      if (mounted) {
        await context.read<AuthProvider>().bootstrap();
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  String getStepTitle(int step) {
    switch (step) {
      case 0:
        return "Basic Info";
      case 1:
        return "Write a Bio";
      case 2:
        return "Your Gender";
      case 3:
        return "Marital Status";
      case 4:
        return "Your Location";
      case 5:
        return "Emotional Readiness";
      case 6:
        return "Languages";
      case 7:
        return "Children Status";
      case 8:
        return "Height";
      case 9:
        return "Looking For";
      case 10:
        return "Education";
      case 11:
        return "Profession";
      case 12:
        return "Habits";
      default:
        return "Onboarding";
    }
  }

  String getStepDescription(int step) {
    switch (step) {
      case 0:
        return "Let's start with your name and date of birth to set up your profile.";
      case 1:
        return "Describe yourself in a few words. Let others know who you are.";
      case 2:
        return "Select your gender identity to help find relevant recommendations.";
      case 3:
        return "Select your current marital status.";
      case 4:
        return "Let others know where you are based to find local matches.";
      case 5:
        return "Reflect on and choose your current emotional readiness level.";
      case 6:
        return "Select all the languages you speak comfortably.";
      case 7:
        return "Do you have children or plan to have children?";
      case 8:
        return "Choose your height in centimeters.";
      case 9:
        return "What type of relationship or connection are you looking for?";
      case 10:
        return "Select your highest level of completed education.";
      case 11:
        return "What is your profession or current occupation?";
      case 12:
        return "Let others know your smoking and drinking habits.";
      default:
        return "Please fill out this step to continue.";
    }
  }

  Widget buildCurrentStep() {
    switch (currentStep) {
      case 0:
        return BasicInfoStep(
          firstNameCtrl: firstNameCtrl,
          lastNameCtrl: lastNameCtrl,
          dateOfBirth: dateOfBirth,
          onFirstNameChanged: (v) {
            setState(() => firstName = v);
            saveToCache('onboarding_first_name', v);
          },
          onLastNameChanged: (v) {
            setState(() => lastName = v);
            saveToCache('onboarding_last_name', v);
          },
          onDateOfBirthChanged: (d) {
            setState(() => dateOfBirth = d);
            saveToCache('onboarding_date_of_birth', d.toIso8601String());
          },
        );
      case 1:
        return BioStep(
          bioCtrl: bioCtrl,
          onBioChanged: (v) {
            setState(() => bio = v);
            saveToCache('onboarding_bio', v);
          },
        );
      case 2:
        return GenderStep(
          selectedGender: gender,
          onGenderChanged: (v) {
            setState(() => gender = v);
            saveToCache('onboarding_gender', v);
          },
        );
      case 3:
        return MaritalStatusStep(
          selectedMaritalStatus: maritalStatus,
          onMaritalStatusChanged: (v) {
            setState(() => maritalStatus = v);
            saveToCache('onboarding_marital_status', v);
          },
        );
      case 4:
        return const LocationStep();
      case 5:
        return EmotionalReadinessStep(
          selectedReadiness: emotionalReadiness,
          onReadinessChanged: (v) {
            setState(() => emotionalReadiness = v);
            saveToCache('onboarding_emotional_readiness', v);
          },
        );
      case 6:
        return LanguagesStep(
          selectedLanguages: languages,
          onLanguageToggled: (l) {
            setState(() {
              if (languages.contains(l)) {
                languages.remove(l);
              } else {
                languages.add(l);
              }
            });
            saveToCache('onboarding_languages', languages);
          },
        );
      case 7:
        return ChildrenStep(
          selectedChildrenStatus: childrenStatus,
          onChildrenStatusChanged: (v) {
            setState(() => childrenStatus = v);
            saveToCache('onboarding_children_status', v);
          },
        );
      case 8:
        return HeightStep(
          heightCm: heightCm,
          onHeightChanged: (v) {
            setState(() {
              heightCm = v;
              heightCtrl.text = v.toString();
            });
            saveToCache('onboarding_height_cm', v);
          },
        );
      case 9:
        return LookingForStep(
          selectedLookingFor: lookingFor,
          onLookingForChanged: (v) {
            setState(() => lookingFor = v);
            saveToCache('onboarding_looking_for', v);
          },
        );
      case 10:
        return EducationStep(
          selectedEducation: highestEducation,
          onEducationChanged: (v) {
            setState(() => highestEducation = v);
            saveToCache('onboarding_highest_education', v);
          },
        );
      case 11:
        return ProfessionStep(
          professionCtrl: professionCtrl,
          selectedJobId: jobId,
          onProfessionChanged: (v) {
            setState(() => profession = v);
            saveToCache('onboarding_profession', v);
          },
          onJobIdChanged: (v) {
            setState(() => jobId = v);
            saveToCache('onboarding_job_id', v);
          },
        );
      case 12:
        return HabitsStep(
          drinkingHabit: drinkingHabit,
          smokingHabit: smokingHabit,
          onDrinkingChanged: (v) {
            setState(() => drinkingHabit = v);
            saveToCache('onboarding_drinking_habit', v);
          },
          onSmokingChanged: (v) {
            setState(() => smokingHabit = v);
            saveToCache('onboarding_smoking_habit', v);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> handleBackPress() async {
    if (currentStep > 0) {
      back();
      return;
    }
    if (!mounted) return;
    await CustomBottomSheet.show(
      context: context,
      type: BottomSheetType.confirmation,
      title: 'Exit App',
      message: 'Are you sure you want to exit the app?',
      primaryButtonText: 'Exit',
      onPrimaryPressed: () {
        SystemNavigator.pop();
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        context.pop();
      },
      imagePath: 'assets/images/illustrations/exit.png',
    );
  }
}
