import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/country_helper.dart';

class DetailItem {
  final IconData? icon;
  final Widget? customLeading;
  final String label;
  final String value;

  const DetailItem({
    this.icon,
    this.customLeading,
    required this.label,
    required this.value,
  });
}

/// Displays a card-style grid of profile detail rows.
class ProfileDetailsGrid extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileDetailsGrid({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final details = _buildDetailItems();
    if (details.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: details.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = details[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: item.customLeading != null
                          ? item.customLeading!
                          : Icon(
                              item.icon,
                              size: 22,
                              color: Theme.of(context).primaryColor,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.6) ??
                                Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 200.ms);
  }

  List<DetailItem> _buildDetailItems() {
    final p = profile;
    final items = <DetailItem>[];

    if (p['motherTongue'] != null) {
      items.add(
        DetailItem(
          icon: Icons.translate_rounded,
          label: 'Language',
          value: p['motherTongue'],
        ),
      );
    }
    if (p['heightCm'] != null) {
      items.add(
        DetailItem(
          icon: Icons.straighten_rounded,
          label: 'Height',
          value: _formatHeight(p['heightCm']),
        ),
      );
    }
    if (p['maritalStatus'] != null) {
      items.add(
        DetailItem(
          icon: Icons.favorite_border,
          label: 'Marital Status',
          value: _formatEnum(p['maritalStatus']),
        ),
      );
    }
    if (p['highestEducation'] != null) {
      String readableEducation(String value) {
        switch (value) {
          case 'HIGH_SCHOOL':
            return 'High School';
          case 'DIPLOMA_CERTIFICATE':
            return 'Diploma / Certificate';
          case 'BACHELORS':
            return "Bachelor's Degree";
          case 'MASTERS':
            return "Master's Degree";
          case 'DOCTORATE':
            return 'Doctorate / PhD';
          case 'OTHER':
            return 'Other';
          default:
            return _formatEnum(value);
        }
      }

      items.add(
        DetailItem(
          icon: Icons.school_outlined,
          label: 'Education',
          value: readableEducation(p['highestEducation']),
        ),
      );
    }
    if (p['occupation'] != null) {
      items.add(
        DetailItem(
          icon: Icons.work_outline_rounded,
          label: 'Profession',
          value: p['occupation'],
        ),
      );
    }

    if (p['gender'] != null) {
      items.add(
        DetailItem(
          icon: Icons.person_outline_rounded,
          label: 'Gender',
          value: _formatEnum(p['gender']),
        ),
      );
    }
    if (p['country'] != null) {
      final countryCode = CountryHelper.getCode(p['country']);
      Widget? flagWidget;
      if (countryCode != null) {
        flagWidget = ClipOval(
          child: CountryFlag.fromCountryCode(
            countryCode,
            width: 24,
            height: 24,
          ),
        );
      }
      items.add(
        DetailItem(
          icon: flagWidget == null ? Icons.public_rounded : null,
          customLeading: flagWidget,
          label: 'Country',
          value: p['country'],
        ),
      );
    }
    if (p['childrenStatus'] != null) {
      items.add(
        DetailItem(
          icon: Icons.child_care_rounded,
          label: 'Children',
          value: _formatEnum(p['childrenStatus']),
        ),
      );
    }
    if (p['drinkingHabit'] != null) {
      items.add(
        DetailItem(
          icon: Icons.wine_bar_outlined,
          label: 'Drinking',
          value: _formatEnum(p['drinkingHabit']),
        ),
      );
    }
    if (p['smokingHabit'] != null) {
      items.add(
        DetailItem(
          icon: Icons.smoking_rooms_rounded,
          label: 'Smoking',
          value: _formatEnum(p['smokingHabit']),
        ),
      );
    }

    if (p['languages'] != null && (p['languages'] as List).isNotEmpty) {
      items.add(
        DetailItem(
          icon: Icons.language_rounded,
          label: 'Languages',
          value: (p['languages'] as List).join(', '),
        ),
      );
    }
    if (p['lookingFor'] != null) {
      items.add(
        DetailItem(
          icon: Icons.search_rounded,
          label: 'Looking For',
          value: _formatEnum(p['lookingFor']),
        ),
      );
    }
    if (p['relationshipTimeline'] != null) {
      items.add(
        DetailItem(
          icon: Icons.timeline_rounded,
          label: 'Timeline',
          value: _formatEnum(p['relationshipTimeline']),
        ),
      );
    }

    return items;
  }

  String _formatHeight(int cm) {
    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$feet\'$inches" ($cm cm)';
  }

  String _formatEnum(String value) {
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
