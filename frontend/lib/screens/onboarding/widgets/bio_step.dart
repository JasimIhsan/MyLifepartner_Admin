import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';

class BioStep extends StatelessWidget {
  final TextEditingController bioCtrl;
  final ValueChanged<String> onBioChanged;

  const BioStep({super.key, required this.bioCtrl, required this.onBioChanged});

  @override
  Widget build(BuildContext context) {
    const templates = [
      (
        'Balanced & Caring',
        'I am a family-oriented individual who values honesty, kindness, and deep conversations. I enjoy traveling, reading, and exploring new cuisines, and I am looking for a life partner to share this journey with.',
      ),
      (
        'Ambitious & Active',
        'An ambitious professional who loves balancing career goals with personal growth. I enjoy outdoor activities, fitness, and weekend getaways. Looking for someone supportive and ready for a serious commitment.',
      ),
      (
        'Creative & Curious',
        'A creative soul with a passion for art, music, and travel. I love learning new things, visiting museums, and spending time in nature. Looking for an open-minded partner who shares similar interests.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingStepTitle(title: "Tell us about yourself"),
        const SizedBox(height: 20),
        const OnboardingSectionLabel(
          text: "Write a short bio (min 50 characters)",
        ),
        OnboardingInputField(
          controller: bioCtrl,
          hint:
              "Describe your personality, interests, and what you are looking for in a partner...",
          keyboardType: TextInputType.multiline,
          capitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(1000)],
          onChanged: onBioChanged,
          minLines: 4,
          maxLines: 8,
          errorText: bioCtrl.text.isNotEmpty && bioCtrl.text.trim().length < 50
              ? "Bio must be at least 50 characters (current: ${bioCtrl.text.trim().length})"
              : null,
        ),
        const SizedBox(height: 10),
        const OnboardingSectionLabel(
          text: "Need inspiration? Choose a starting template:",
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final (title, text) = templates[index];
              final isSelected = bioCtrl.text == text;

              return GestureDetector(
                onTap: () {
                  bioCtrl.text = text;
                  onBioChanged(text);
                },
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : const Color(0xFFF0E6E6),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
