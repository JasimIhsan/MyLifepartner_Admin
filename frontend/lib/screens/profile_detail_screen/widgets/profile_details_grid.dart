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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: details.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.customLeading != null)
                    item.customLeading!
                  else if (item.icon != null)
                    Icon(item.icon, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    item.value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
      items.add(
        DetailItem(
          icon: Icons.school_outlined,
          label: 'Education',
          value: p['highestEducation'],
        ),
      );
    }
    if (p['occupation'] != null) {
      items.add(
        DetailItem(
          icon: Icons.work_outline_rounded,
          label: 'Occupation',
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
            width: 18,
            height: 18,
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
