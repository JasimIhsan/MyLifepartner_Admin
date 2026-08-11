import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/models/partner_preference.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/core/app_colors.dart';

mixin EditPartnerPreferenceControllerState<T extends StatefulWidget>
    on State<T> {
  final ProfileRepository profileRepository = ProfileRepository();

  bool isInitialLoading = true;
  bool isSaving = false;

  RangeValues ageRange = const RangeValues(25, 45);
  RangeValues _initialAgeRange = const RangeValues(25, 45);

  final List<String> maritalStatus = [];
  final List<String> languages = [];
  List<String> _initialMaritalStatus = [];
  List<String> _initialLanguages = [];

  @override
  void initState() {
    super.initState();
    fetchPartnerPreference();
  }

  bool get isValid => maritalStatus.isNotEmpty && languages.isNotEmpty;

  bool get isDirty {
    return ageRange.start.round() != _initialAgeRange.start.round() ||
        ageRange.end.round() != _initialAgeRange.end.round() ||
        !_sameItems(maritalStatus, _initialMaritalStatus) ||
        !_sameItems(languages, _initialLanguages);
  }

  bool get canSave => isDirty && isValid && !isSaving && !isInitialLoading;

  Future<void> fetchPartnerPreference() async {
    setState(() => isInitialLoading = true);

    try {
      final preference = await profileRepository.getPartnerPreference();
      final nextAgeRange = _ageRangeFromPreference(preference);

      setState(() {
        ageRange = nextAgeRange;
        _initialAgeRange = nextAgeRange;
        maritalStatus
          ..clear()
          ..addAll(preference?.maritalStatus ?? const []);
        languages
          ..clear()
          ..addAll(preference?.motherTongue ?? const []);
        _initialMaritalStatus = List<String>.from(maritalStatus);
        _initialLanguages = List<String>.from(languages);
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => isInitialLoading = false);
      }
    }
  }

  void updateAgeRange(RangeValues values) {
    final start = values.start.round().clamp(18, 100).toDouble();
    final end = values.end.round().clamp(18, 100).toDouble();
    setState(() => ageRange = RangeValues(start, end));
  }

  void toggleMaritalStatus(String value) {
    setState(() {
      maritalStatus.contains(value)
          ? maritalStatus.remove(value)
          : maritalStatus.add(value);
    });
  }

  void toggleLanguage(String value) {
    setState(() {
      languages.contains(value)
          ? languages.remove(value)
          : languages.add(value);
    });
  }

  Future<void> savePartnerPreference() async {
    if (!isValid) {
      _showSnackBar('Select at least one marital status and language');
      return;
    }

    setState(() => isSaving = true);

    try {
      await profileRepository.updatePartnerPreference({
        'ageFrom': ageRange.start.round(),
        'ageTo': ageRange.end.round(),
        'maritalStatus': maritalStatus,
        'motherTongue': languages,
      });

      if (!mounted) return;

      _showSnackBar('Partner preferences updated successfully');
      context.pop(true);
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void handleBackPress() {
    if (isSaving) return;

    if (!isDirty) {
      context.pop(false);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        if (mounted) context.pop(false); // Pop screen
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

  RangeValues _ageRangeFromPreference(PartnerPreference? preference) {
    final start = _boundedAge(preference?.ageFrom, 25);
    final end = _boundedAge(preference?.ageTo, 45);

    if (start <= end) {
      return RangeValues(start, end);
    }

    return RangeValues(end, start);
  }

  double _boundedAge(int? value, int fallback) {
    return (value ?? fallback).clamp(18, 100).toDouble();
  }

  bool _sameItems(List<String> first, List<String> second) {
    if (first.length != second.length) return false;

    final firstSet = first.toSet();
    return second.every(firstSet.contains);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.black),
    );
  }
}
