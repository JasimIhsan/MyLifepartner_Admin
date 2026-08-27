import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

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

class WebEditPartnerPreferenceForm extends StatefulWidget {
  final RangeValues ageRange;
  final ValueChanged<RangeValues> onAgeChanged;
  final List<String> selectedMaritalStatus;
  final ValueChanged<String> onMaritalStatusToggle;
  final List<String> selectedLanguages;
  final ValueChanged<String> onLanguageToggle;

  const WebEditPartnerPreferenceForm({
    super.key,
    required this.ageRange,
    required this.onAgeChanged,
    required this.selectedMaritalStatus,
    required this.onMaritalStatusToggle,
    required this.selectedLanguages,
    required this.onLanguageToggle,
  });

  @override
  State<WebEditPartnerPreferenceForm> createState() =>
      _WebEditPartnerPreferenceFormState();
}

class _WebEditPartnerPreferenceFormState extends State<WebEditPartnerPreferenceForm> {
  final Color primary = const Color(0xFFFF3B30); // Red

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _LanguageSelectionDialog(
          selectedLanguages: widget.selectedLanguages,
          onToggle: widget.onLanguageToggle,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Age Range ──────────────────────────────────────────────────────────
        Text(
          'Age Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              '${widget.ageRange.start.round()} Years',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: primary,
                  inactiveTrackColor: primary.withValues(alpha: 0.15),
                  thumbColor: primary,
                  overlayColor: primary.withValues(alpha: 0.1),
                  trackHeight: 4,
                  rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
                ),
                child: RangeSlider(
                  values: widget.ageRange,
                  min: 18,
                  max: 100,
                  divisions: 82,
                  onChanged: widget.onAgeChanged,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${widget.ageRange.end.round()} Years',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: theme.dividerColor.withValues(alpha: 0.15), height: 1),
        const SizedBox(height: 32),

        // ── Marital Status ────────────────────────────────────────────────────
        Text(
          'Marital Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _maritalStatusOptions.map((option) {
            final isSelected = widget.selectedMaritalStatus.contains(option.value);
            return _ImageStyleChip(
              label: option.label,
              isSelected: isSelected,
              onTap: () => widget.onMaritalStatusToggle(option.value),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Divider(color: theme.dividerColor.withValues(alpha: 0.15), height: 1),
        const SizedBox(height: 32),

        // ── Languages ─────────────────────────────────────────────────────────
        Text(
          'Languages',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...widget.selectedLanguages.map((lang) {
              return _ImageStyleChip(
                label: lang,
                isSelected: true,
                showCross: true,
                onTap: () => widget.onLanguageToggle(lang),
              );
            }),
            InkWell(
              onTap: _showLanguageDialog,
              borderRadius: BorderRadius.circular(8),
              child: DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  color: Colors.grey.shade400,
                  strokeWidth: 1.5,
                  dashPattern: const <double>[6, 4],
                  radius: const Radius.circular(8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.grey.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Add More',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: theme.dividerColor.withValues(alpha: 0.15), height: 1),
      ],
    );
  }
}

class _ImageStyleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showCross;

  const _ImageStyleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showCross = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFFF3B30);
    // Based on the image, all options might have this pink/red styling or only selected ones.
    // The image shows them all pink. We will style them as selected if isSelected is true.
    // If not selected, they could just be grey outlines.
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primary.withValues(alpha: 0.3) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? primary : Colors.grey.shade700,
              ),
            ),
            if (showCross) ...[
              const SizedBox(width: 8),
              Icon(Icons.close, size: 14, color: primary.withValues(alpha: 0.6)),
            ]
          ],
        ),
      ),
    );
  }
}

class _LanguageSelectionDialog extends StatefulWidget {
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggle;

  const _LanguageSelectionDialog({
    required this.selectedLanguages,
    required this.onToggle,
  });

  @override
  State<_LanguageSelectionDialog> createState() => _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<_LanguageSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late List<String> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = List.from(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFFF3B30);

    final filtered = _languageOptions
        .where((lang) =>
            lang.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Languages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search languages...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final lang = filtered[index];
                  final isSelected = _localSelected.contains(lang);
                  return CheckboxListTile(
                    title: Text(lang),
                    value: isSelected,
                    activeColor: primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _localSelected.add(lang);
                        } else {
                          _localSelected.remove(lang);
                        }
                      });
                      widget.onToggle(lang);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
