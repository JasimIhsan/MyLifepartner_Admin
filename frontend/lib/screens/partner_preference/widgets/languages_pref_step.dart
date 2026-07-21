import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class LanguagesPrefStep extends StatefulWidget {
  final List<String> selectedLanguages;
  final ValueChanged<String> onToggle;

  const LanguagesPrefStep({
    super.key,
    required this.selectedLanguages,
    required this.onToggle,
  });

  @override
  State<LanguagesPrefStep> createState() => _LanguagesPrefStepState();
}

class _LanguagesPrefStepState extends State<LanguagesPrefStep> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<String> _allLangs = const [
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter remaining languages that match search and are NOT selected
    final filteredLangs = _allLangs
        .where((l) =>
            l.toLowerCase().contains(_searchQuery.toLowerCase()) &&
            !widget.selectedLanguages.contains(l))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingStepTitle(
          title: "Any language preference?",
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pick your languages",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.selectedLanguages.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.selectedLanguages.map((lang) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => widget.onToggle(lang),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.primary,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _searchCtrl,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search languages",
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textLight,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: filteredLangs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final lang = entry.value;
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        title: Text(
                          lang,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        onTap: () {
                          widget.onToggle(lang);
                        },
                      ),
                      if (index < filteredLangs.length - 1)
                        const Divider(
                          height: 1,
                          color: AppColors.divider,
                        ),
                    ],
                  );
                }).toList(),
              ),
              if (filteredLangs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      "No matching languages found",
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
