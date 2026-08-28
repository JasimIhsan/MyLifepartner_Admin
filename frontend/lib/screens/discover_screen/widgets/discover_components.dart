import 'dart:ui';

import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/country_helper.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
import 'package:life_partner_again/services/image_access_service.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/custom_button.dart';

import 'package:life_partner_again/widgets/verified_icon.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';

class ProfileBrowserCard extends StatelessWidget {
  final MatchRecommendation profile;
  final VoidCallback onInterest;
  final VoidCallback onNotInterested;
  final VoidCallback? onReturnFromDetail;
  final bool isActioning;
  final String? loadingAction;
  final bool isActioned;

  const ProfileBrowserCard({
    super.key,
    required this.profile,
    required this.onInterest,
    required this.onNotInterested,
    this.onReturnFromDetail,
    this.isActioning = false,
    this.loadingAction,
    this.isActioned = false,
  });

  MatchImage? get _profileImage => profile.primaryOrFirstImage;

  bool get _isBlurred => _profileImage?.isBlurred ?? false;

  bool _isNewProfile(String isoString) {
    try {
      if (isoString.isEmpty) return false;
      final date = DateTime.parse(isoString);
      final diff = DateTime.now().difference(date);
      return diff.inDays <= 7;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await context.push('/profile/${profile.id}');
        if (onReturnFromDetail != null) {
          onReturnFromDetail!();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Profile Hero Image
            _profileImage != null
                ? CachedAppImage(
                    imageId: _profileImage!.imageId,
                    presignedImageUrl: _profileImage!.presignedImageUrl,
                    isBlurred: _profileImage!.isBlurred,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        _placeholder(context, showLoading: true),
                    errorWidget: (_, __, ___) => _placeholder(context),
                  )
                : _placeholder(context),

            // Dark Gradient Overlay at the bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
            if (_isNewProfile(profile.createdAt.toString()))
              Positioned(
                top: 24,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              ),
            // Detail Overlay & Action Buttons
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child:
                  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildProfileInfo(context),
                          const SizedBox(height: 32),
                          ActionButtonsRow(
                            onInterest: onInterest,
                            onNotInterested: onNotInterested,
                            isActioning: isActioning,
                            loadingAction: loadingAction,
                            isActioned: isActioned,
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.1, end: 0),
            ),

            // Country Flag Top Right
            if (CountryHelper.getCode(profile.country) != null)
              Positioned(
                top: 24,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CountryFlag.fromCountryCode(
                      CountryHelper.getCode(profile.country)!,
                      width: 36,
                      height: 36,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              ),
            if (_isBlurred)
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.viewerPrivacyEnabled
                            ? 'Your profile is private'
                            : 'Photos are private',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.viewerPrivacyEnabled
                            ? 'You need access to see ${profile.name}\'s photos.'
                            : 'Request access to see ${profile.name}\'s photos.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      RequestAccessButton(profile: profile),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${profile.name}, ${profile.age}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (profile.isVerified ||
                profile.isPremium ||
                profile.isFoundingMember) ...[
              const SizedBox(width: 8),
              VerifiedIconWidget(
                isVerified: profile.isVerified,
                isFoundingMember: profile.isFoundingMember,
                isPremium: profile.isPremium,
                size: 24,
              ),
            ],
            if (profile.isFoundingMember) ...[
              const SizedBox(width: 8),
              const FoundingMemberBadge(size: 24, isOverlay: true),
            ],
          ],
        ),
        const SizedBox(height: 4),
        if (profile.occupation != null && profile.occupation!.trim().isNotEmpty)
          _buildInfoRow(LucideIcons.briefcase, profile.occupation!),
        if (profile.maritalStatus != null)
          _buildInfoRow(LucideIcons.heart, _formatEnum(profile.maritalStatus!)),
        if (_formatLocation(profile) != null)
          _buildInfoRow(LucideIcons.map_pin, _formatLocation(profile)!),
      ],
    );
  }

  String? _formatLocation(MatchRecommendation profile) {
    final parts = [
      profile.city,
      profile.state,
      profile.country,
    ].where((part) => part != null && part.trim().isNotEmpty).toList();

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, {bool showLoading = false}) =>
      Container(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        child: showLoading
            ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : null,
      );

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

class SideNavigationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLeft;

  final Key? buttonKey;

  const SideNavigationButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isLeft,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child:
          Container(
                margin: EdgeInsets.only(
                  left: isLeft ? 25 : 0,
                  right: !isLeft ? 25 : 0,
                ),
                child: SizedBox(
                  key: buttonKey,
                  width: 55,
                  height: 55,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
                duration: 500.ms,
              ),
    );
  }
}

class ActionButtonsRow extends StatelessWidget {
  final VoidCallback onInterest;
  final VoidCallback onNotInterested;
  final bool isActioning;
  final String? loadingAction;
  final bool isActioned;

  const ActionButtonsRow({
    super.key,
    required this.onInterest,
    required this.onNotInterested,
    this.isActioning = false,
    this.loadingAction,
    this.isActioned = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ActionButton(
            label: '',
            icon: Icons.heart_broken,
            onTap: (isActioning || isActioned) ? () {} : onNotInterested,
            primary: false,
            isLoading: isActioning && loadingAction == 'LEFT',
            isDisabled: isActioned,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ActionButton(
            label: '',
            icon: Icons.favorite_rounded,
            onTap: (isActioning || isActioned) ? () {} : onInterest,
            primary: true,
            isLoading: isActioning && loadingAction == 'RIGHT',
            isDisabled: isActioned,
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Border? borderColor;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color buttonColor =
        backgroundColor ??
        (isDisabled
            ? Colors.grey.shade400
            : (primary ? Theme.of(context).primaryColor : Colors.transparent));

    final Border? borderStyle =
        borderColor ??
        ((primary || isDisabled)
            ? null
            : Border.all(color: Colors.white30, width: 1.5));

    final Color effectiveIconColor = iconColor ?? Colors.white;
    final Color effectiveTextColor = textColor ?? Colors.white;

    return GestureDetector(
      onTap: (isLoading || isDisabled) ? null : onTap,
      child: Opacity(
        opacity: (isLoading || isDisabled) ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(100),
            border: borderStyle,
            boxShadow:
                (primary &&
                    !isDisabled &&
                    !isLoading &&
                    backgroundColor == null)
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: effectiveIconColor,
                  ),
                )
              else ...[
                Icon(icon, color: effectiveIconColor, size: 20),
                if (label.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class RequestAccessButton extends StatefulWidget {
  final MatchRecommendation profile;
  const RequestAccessButton({super.key, required this.profile});

  @override
  State<RequestAccessButton> createState() => _RequestAccessButtonState();
}

class _RequestAccessButtonState extends State<RequestAccessButton> {
  bool _isLoading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _status = widget.profile.imageAccessRequestStatus;
  }

  Future<void> _sendRequest() async {
    setState(() {
      _isLoading = true;
    });
    final success = await ImageAccessService.requestAccess(
      widget.profile.userId,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _status = 'PENDING';
        }
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access request sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send access request')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'PENDING') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Access Pending',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (_status == 'APPROVED') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        onPressed: _isLoading ? () {} : _sendRequest,
        text: _isLoading ? 'Sending...' : 'Request Access',
        height: 40,
        borderRadius: 12,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
