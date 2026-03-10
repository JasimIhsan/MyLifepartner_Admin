import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';

class DetailItem {
  final IconData icon;
  final String label;
  final String value;

  const DetailItem(this.icon, this.label, this.value);
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
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: details.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == details.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.icon,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                item.value,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 54, endIndent: 14),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 200.ms);
  }

  List<DetailItem> _buildDetailItems() {
    final p = profile;
    final items = <DetailItem>[];

    if (p['religion'] != null) {
      items.add(DetailItem(Icons.auto_awesome_outlined, 'Religion',
          p['religion']));
    }
    if (p['motherTongue'] != null) {
      items.add(DetailItem(Icons.translate_rounded, 'Mother Tongue',
          p['motherTongue']));
    }
    if (p['heightCm'] != null) {
      items.add(DetailItem(Icons.straighten_rounded, 'Height',
          _formatHeight(p['heightCm'])));
    }
    if (p['maritalStatus'] != null) {
      items.add(DetailItem(Icons.favorite_border, 'Marital Status',
          _formatEnum(p['maritalStatus'])));
    }
    if (p['highestEducation'] != null) {
      items.add(DetailItem(Icons.school_outlined, 'Education',
          p['highestEducation']));
    }
    if (p['occupation'] != null) {
      items.add(DetailItem(Icons.work_outline_rounded, 'Occupation',
          p['occupation']));
    }
    if (p['annualIncome'] != null) {
      items.add(DetailItem(Icons.account_balance_wallet_outlined,
          'Annual Income', '₹${_formatIncome(p['annualIncome'])}'));
    }
    if (p['gender'] != null) {
      items.add(DetailItem(Icons.person_outline_rounded, 'Gender',
          _formatEnum(p['gender'])));
    }
    if (p['country'] != null) {
      items.add(DetailItem(Icons.public_rounded, 'Country', p['country']));
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
        .map((w) =>
            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  String _formatIncome(int amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)} Cr';
    }
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)} L';
    }
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)} K';
    return amount.toString();
  }
}
