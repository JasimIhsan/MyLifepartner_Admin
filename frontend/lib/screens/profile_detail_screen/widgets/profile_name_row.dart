import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/verified_profile_bottom_sheet.dart';

class ProfileNameRow extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool isOverlay;

  const ProfileNameRow({
    super.key,
    required this.profile,
    this.isOverlay = false,
  });

  String _formatLastLogin(String isoString) {
    try {
      if (isoString.isEmpty) return '';
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      if (diff.inDays == 0) {
        if (diff.inHours == 0) return 'Active just now';
        return 'Active ${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'Active yesterday';
      } else {
        return 'Active ${diff.inDays}d ago';
      }
    } catch (_) {
      return '';
    }
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

  @override
  Widget build(BuildContext context) {
    final textColor = isOverlay ? Colors.white : AppColors.textPrimary;
    final subTextColor = isOverlay
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// LEFT SIDE (flexible content)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 NAME + VERIFIED (same row — FIXED)
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile['name'] ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),

                  if (profile['isVerified'] == true) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => VerifiedProfileBottomSheet(
                            profileName: profile['name'] ?? 'Unknown',
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/icons/verified_icon.png',
                        width: 20,
                        height: 20,
                      ),
                    ),
                  ],
                  if (profile['isBlocked'] == true) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Blocked',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 2),

              /// 🔹 AGE
              Text(
                '${profile['age'] ?? ''}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: subTextColor,
                ),
              ),

              /// 🔹 META (wrap = no overflow ever)
              if (profile['maritalStatus'] != null ||
                  profile['city'] != null ||
                  profile['state'] != null ||
                  profile['lastLoginAt'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      /// MARITAL STATUS
                      if (profile['maritalStatus'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 16,
                              color: subTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatEnum(profile['maritalStatus']),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),

                      /// LOCATION
                      if (profile['city'] != null || profile['state'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: subTextColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [
                                  profile['city'],
                                  profile['state'],
                                ].where((e) => e != null).join(', '),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: subTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                      /// LAST ACTIVE
                      if (profile['lastLoginAt'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: const Color.fromARGB(255, 96, 186, 101),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatLastLogin(
                                profile['lastLoginAt'].toString(),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color.fromARGB(255, 96, 186, 101),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        /// RIGHT SIDE (match badge stays fixed)
        _buildMatchBadge(profile['matchPercentage'] ?? 0),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildMatchBadge(int pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'match',
            style: TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
