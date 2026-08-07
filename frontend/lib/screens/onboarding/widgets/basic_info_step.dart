import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import 'package:life_partner_again/screens/onboarding/widgets/primay_date_picker.dart';

class BasicInfoStep extends StatefulWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final DateTime? dateOfBirth;
  final ValueChanged<String> onFirstNameChanged;
  final ValueChanged<String> onLastNameChanged;
  final ValueChanged<DateTime> onDateOfBirthChanged;

  const BasicInfoStep({
    super.key,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.dateOfBirth,
    required this.onFirstNameChanged,
    required this.onLastNameChanged,
    required this.onDateOfBirthChanged,
  });

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  late final TextEditingController _dobCtrl;

  @override
  void initState() {
    super.initState();
    _dobCtrl = TextEditingController(
      text: widget.dateOfBirth != null ? _formatDate(widget.dateOfBirth!) : '',
    );
  }

  @override
  void didUpdateWidget(covariant BasicInfoStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateOfBirth != oldWidget.dateOfBirth) {
      _dobCtrl.text = widget.dateOfBirth != null
          ? _formatDate(widget.dateOfBirth!)
          : '';
    }
  }

  @override
  void dispose() {
    _dobCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  void _showDatePickerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: PrimayDatePicker(
              initialDate: widget.dateOfBirth,
              onDateChanged: (date) {
                widget.onDateOfBirthChanged(date);
                setState(() {
                  _dobCtrl.text = _formatDate(date);
                });
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\']+$");

    String? getFirstNameError() {
      if (widget.firstNameCtrl.text.isNotEmpty &&
          !nameRegex.hasMatch(widget.firstNameCtrl.text)) {
        return "Only letters, spaces, hyphens, and apostrophes allowed";
      }
      return null;
    }

    String? getLastNameError() {
      if (widget.lastNameCtrl.text.isNotEmpty &&
          !nameRegex.hasMatch(widget.lastNameCtrl.text)) {
        return "Only letters, spaces, hyphens, and apostrophes allowed";
      }
      return null;
    }

    return Column(
      children: [
        const OnboardingStepTitle(title: "Hey! Let's talk little about you"),
        const SizedBox(height: 20),
        const OnboardingSectionLabel(text: "First Name"),
        OnboardingInputField(
          controller: widget.firstNameCtrl,
          hint: 'First Name',
          errorText: getFirstNameError(),
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          onChanged: widget.onFirstNameChanged,
        ),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(text: "Last Name"),
        OnboardingInputField(
          controller: widget.lastNameCtrl,
          hint: 'Last Name',
          errorText: getLastNameError(),
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          onChanged: widget.onLastNameChanged,
        ),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(text: "Date of Birth"),
        OnboardingInputField(
          controller: _dobCtrl,
          hint: 'Select Date of Birth',
          isReadonly: true,
          onTap: _showDatePickerDialog,
          suffixIcon: Icon(
            Icons.calendar_today_rounded,
            color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        // AgeStatusWidget(dateOfBirth: widget.dateOfBirth),
      ],
    );
  }
}
