import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public widget — signature unchanged so the mobile screen compiles as-is.
// ─────────────────────────────────────────────────────────────────────────────

class EditPartnerPreferenceForm extends StatelessWidget {
  final RangeValues ageRange;
  final ValueChanged<RangeValues> onAgeChanged;
  final List<String> selectedMaritalStatus;
  final ValueChanged<String> onMaritalStatusToggle;
  final List<String> selectedLanguages;
  final ValueChanged<String> onLanguageToggle;

  const EditPartnerPreferenceForm({
    super.key,
    required this.ageRange,
    required this.onAgeChanged,
    required this.selectedMaritalStatus,
    required this.onMaritalStatusToggle,
    required this.selectedLanguages,
    required this.onLanguageToggle,
  });

  void _showAgeRangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        RangeValues currentRange = ageRange;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            'Select Age Range',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close,
                              size: 24,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Choose the age range\nyou're comfortable with",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AgeRangePickerDialogEditor(
                      ageRange: currentRange,
                      onChanged: (values) {
                        setStateDialog(() => currentRange = values);
                        onAgeChanged(values);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguageModal(BuildContext context) {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Languages',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                _LanguageSelectionModalContent(
                  initialLanguages: selectedLanguages,
                  onToggle: onLanguageToggle,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select Languages',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _LanguageSelectionModalContent(
                  initialLanguages: selectedLanguages,
                  onToggle: onLanguageToggle,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showMaritalStatusModal(BuildContext context) {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Marital Status',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                _MaritalStatusSelector(
                  initialValues: selectedMaritalStatus,
                  onToggle: onMaritalStatusToggle,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
              const SizedBox(height: 24),
              Text(
                'Select Marital Status',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              _MaritalStatusSelector(
                initialValues: selectedMaritalStatus,
                onToggle: onMaritalStatusToggle,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Partner Preferences',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preferences help us find better matches',
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),

        // ── Age Range ─────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _showAgeRangeDialog(context),
          child: _PreferenceCard(
            icon: Icons.calendar_today_rounded,
            title: 'Age Range',
            description: 'Select the ideal age range',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${ageRange.start.round()} — ${ageRange.end.round()} yrs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFFFF3B30),
                ),
              ],
            ),
          ),
        ),

        // ── Marital Status ────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _showMaritalStatusModal(context),
          child: _PreferenceCard(
            icon: Icons.favorite_border_rounded,
            title: 'Marital Status',
            description: 'Choose the statuses you\'re open to',
            errorText: selectedMaritalStatus.isEmpty
                ? 'Select at least one option'
                : null,
            child: selectedMaritalStatus.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedMaritalStatus.map((status) {
                      final option = _maritalStatusOptions.firstWhere(
                        (o) => o.value == status,
                        orElse: () => _Option(status, status),
                      );
                      return _SelectedPill(
                        label: option.label,
                        onRemove: () {
                          HapticFeedback.lightImpact();
                          onMaritalStatusToggle(status);
                        },
                      );
                    }).toList(),
                  )
                : Text(
                    'Tap to select marital status',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
          ),
        ),

        // ── Languages ─────────────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _showLanguageModal(context),
          child: _PreferenceCard(
            icon: Icons.translate_rounded,
            title: 'Languages',
            description: 'Languages your partner should speak',
            errorText: selectedLanguages.isEmpty
                ? 'Select at least one language'
                : null,
            child: selectedLanguages.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedLanguages.map((lang) {
                      return _SelectedPill(
                        label: lang,
                        onRemove: () {
                          HapticFeedback.lightImpact();
                          onLanguageToggle(lang);
                        },
                      );
                    }).toList(),
                  )
                : Text(
                    'Tap to select languages',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Completion Card ───────────────────────────────────────────────────
        // Container(
        //   width: double.infinity,
        //   padding: const EdgeInsets.all(20),
        //   decoration: BoxDecoration(
        //     color: const Color(0xFFFF3B30).withValues(alpha: 0.05),
        //     borderRadius: BorderRadius.circular(16),
        //   ),
        //   child: Row(
        //     children: [
        //       Container(
        //         width: 48,
        //         height: 48,
        //         decoration: const BoxDecoration(
        //           color: Colors.white,
        //           shape: BoxShape.circle,
        //         ),
        //         child: const Icon(
        //           Icons.favorite_rounded,
        //           color: Color(0xFFFF3B30),
        //           size: 24,
        //         ),
        //       ),
        //       const SizedBox(width: 16),
        //       Expanded(
        //         child: Column(
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           children: [
        //             Text(
        //               "You're all set!",
        //               style: TextStyle(
        //                 fontSize: 16,
        //                 fontWeight: FontWeight.w600,
        //                 color: Theme.of(context).textTheme.bodyLarge?.color,
        //               ),
        //             ),
        //             const SizedBox(height: 4),
        //             Text(
        //               "We'll show you the best matches based on your preferences.",
        //               style: TextStyle(
        //                 fontSize: 13,
        //                 color: Theme.of(context).textTheme.bodySmall?.color,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? errorText;
  final Widget child;

  const _PreferenceCard({
    required this.icon,
    required this.title,
    required this.description,
    this.errorText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFFFF3B30); // Use red

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.textTheme.bodyLarge?.color,
                size: 20,
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Age Range Editor — Cupertino Pickers
// ─────────────────────────────────────────────────────────────────────────────

class _AgeRangePickerDialogEditor extends StatefulWidget {
  final RangeValues ageRange;
  final ValueChanged<RangeValues> onChanged;

  const _AgeRangePickerDialogEditor({
    required this.ageRange,
    required this.onChanged,
  });

  @override
  State<_AgeRangePickerDialogEditor> createState() =>
      _AgeRangePickerDialogEditorState();
}

class _AgeRangePickerDialogEditorState
    extends State<_AgeRangePickerDialogEditor> {
  late int minAge;
  late int maxAge;
  late FixedExtentScrollController _minController;
  late FixedExtentScrollController _maxController;

  @override
  void initState() {
    super.initState();
    minAge = widget.ageRange.start.round();
    maxAge = widget.ageRange.end.round();
    _minController = FixedExtentScrollController(initialItem: minAge - 18);
    _maxController = FixedExtentScrollController(initialItem: maxAge - 18);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = const Color(0xFFFF3B30);
    final actualMin = minAge <= maxAge ? minAge : maxAge;
    final actualMax = maxAge >= minAge ? maxAge : minAge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Minimum age",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                "Maximum age",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  scrollController: _minController,
                  itemExtent: 44,
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  onSelectedItemChanged: (index) {
                    final selectedAge = 18 + index;
                    if (selectedAge > maxAge) {
                      _minController.animateToItem(
                        maxAge - 18,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      HapticFeedback.lightImpact();
                      return;
                    }
                    setState(() => minAge = selectedAge);
                    widget.onChanged(
                      RangeValues(minAge.toDouble(), maxAge.toDouble()),
                    );
                  },
                  children: List.generate(83, (index) {
                    final age = 18 + index;
                    final isSelected = age == minAge;
                    final isInvalid = age > maxAge;
                    return Center(
                      child: Text(
                        age.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          color: isInvalid
                              ? theme.disabledColor.withValues(alpha: 0.3)
                              : (isSelected ? primary : textColor),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "-",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: _maxController,
                  itemExtent: 44,
                  selectionOverlay: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  onSelectedItemChanged: (index) {
                    final selectedAge = 18 + index;
                    if (selectedAge < minAge) {
                      _maxController.animateToItem(
                        minAge - 18,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                      HapticFeedback.lightImpact();
                      return;
                    }
                    setState(() => maxAge = selectedAge);
                    widget.onChanged(
                      RangeValues(minAge.toDouble(), maxAge.toDouble()),
                    );
                  },
                  children: List.generate(83, (index) {
                    final age = 18 + index;
                    final isSelected = age == maxAge;
                    final isInvalid = age < minAge;
                    return Center(
                      child: Text(
                        age.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          color: isInvalid
                              ? theme.disabledColor.withValues(alpha: 0.3)
                              : (isSelected ? primary : textColor),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$actualMin — $actualMax years',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Marital Status Selector — premium animated pill chips
// ─────────────────────────────────────────────────────────────────────────────

class _MaritalStatusSelector extends StatefulWidget {
  final List<String> initialValues;
  final ValueChanged<String> onToggle;

  const _MaritalStatusSelector({
    required this.initialValues,
    required this.onToggle,
  });

  @override
  State<_MaritalStatusSelector> createState() => _MaritalStatusSelectorState();
}

class _MaritalStatusSelectorState extends State<_MaritalStatusSelector> {
  late List<String> _localValues;

  @override
  void initState() {
    super.initState();
    _localValues = List.from(widget.initialValues);
  }

  void _handleToggle(String value) {
    setState(() {
      if (_localValues.contains(value)) {
        _localValues.remove(value);
      } else {
        _localValues.add(value);
      }
    });
    widget.onToggle(value);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _maritalStatusOptions.map((option) {
        final isSelected = _localValues.contains(option.value);
        return _PillChip(
          label: option.label,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            _handleToggle(option.value);
          },
        );
      }).toList(),
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: isDark ? 0.20 : 0.10)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? primary : theme.dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isSelected
                  ? Padding(
                      key: const ValueKey('check'),
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: primary,
                      ),
                    )
                  : const SizedBox(key: ValueKey('empty')),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? primary
                    : theme.textTheme.bodyMedium?.color ??
                          AppColors.textSecondary,
                letterSpacing: isSelected ? -0.1 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Selector — horizontal scroll selected pills + search + refined list
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSelector extends StatefulWidget {
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggle;

  const _LanguageSelector({
    required this.selectedLanguages,
    required this.onToggle,
  });

  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    final filteredLanguages = _languageOptions
        .where(
          (lang) =>
              lang.toLowerCase().contains(_query.toLowerCase()) &&
              !widget.selectedLanguages.contains(lang),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Horizontal scroll row of selected language pills ───────────────
        if (widget.selectedLanguages.isNotEmpty) ...[
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selectedLanguages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final lang = widget.selectedLanguages[index];
                return _SelectedPill(
                  label: lang,
                  onRemove: () {
                    HapticFeedback.lightImpact();
                    widget.onToggle(lang);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Search field ───────────────────────────────────────────────────
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search languages…',
            hintStyle: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodySmall?.color ?? AppColors.textLight,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: theme.textTheme.bodySmall?.color ?? AppColors.textLight,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color:
                          theme.textTheme.bodySmall?.color ??
                          AppColors.textLight,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Language list ──────────────────────────────────────────────────
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              child: filteredLanguages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 28,
                              color:
                                  theme.textTheme.bodySmall?.color ??
                                  AppColors.textLight,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No languages found',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    theme.textTheme.bodySmall?.color ??
                                    AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: filteredLanguages.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final language = filteredLanguages[index];
                        return _LanguageListTile(
                          language: language,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onToggle(language);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageListTile extends StatelessWidget {
  final String language;
  final VoidCallback onTap;

  const _LanguageListTile({required this.language, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color:
                      theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_rounded, size: 16, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedPill extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _SelectedPill({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withValues(alpha: 0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded, size: 13, color: primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Option {
  final String label;
  final String value;

  const _Option(this.label, this.value);
}

const List<_Option> _maritalStatusOptions = [
  _Option('Separated', 'SEPARATED'),
  _Option('Divorced', 'DIVORCED'),
  _Option('Widowed', 'WIDOWED'),
  _Option('Awaiting Divorce', 'AWAITING_DIVORCE'),
];

const List<String> _languageOptions = [
  'English',
  'French',
  'Spanish',
  'German',
  'Italian',
  'Portuguese',
  'Dutch',
  'Russian',
  'Polish',
  'Ukrainian',
  'Romanian',
  'Greek',
  'Turkish',
  'Arabic',
  'Punjabi',
  'Mandarin Chinese',
  'Cantonese',
  'Tagalog',
  'Persian',
  'Urdu',
];

// ─────────────────────────────────────────────────────────────────────────────
// Language Selection Modal State Wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageSelectionModalContent extends StatefulWidget {
  final List<String> initialLanguages;
  final ValueChanged<String> onToggle;

  const _LanguageSelectionModalContent({
    required this.initialLanguages,
    required this.onToggle,
  });

  @override
  State<_LanguageSelectionModalContent> createState() =>
      _LanguageSelectionModalContentState();
}

class _LanguageSelectionModalContentState
    extends State<_LanguageSelectionModalContent> {
  late List<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List.from(widget.initialLanguages);
  }

  void _handleToggle(String lang) {
    setState(() {
      if (_localSelected.contains(lang)) {
        _localSelected.remove(lang);
      } else {
        _localSelected.add(lang);
      }
    });
    widget.onToggle(lang);
  }

  @override
  Widget build(BuildContext context) {
    return _LanguageSelector(
      selectedLanguages: _localSelected,
      onToggle: _handleToggle,
    );
  }
}
