import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_action_bar.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_detail_controller.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/profile_skeleton.dart';
import 'package:life_partner_again/screens/profile_detail_screen/widgets/report_user_dialog.dart';
import 'package:life_partner_again/services/block_service.dart';
import 'package:life_partner_again/widgets/bottomsheet/block_confirmation_bottom_sheet.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/verified_profile_bottom_sheet.dart';
import 'package:provider/provider.dart';

class MobileProfileDetailScreen extends StatefulWidget {
  const MobileProfileDetailScreen({super.key});

  @override
  State<MobileProfileDetailScreen> createState() =>
      _MobileProfileDetailScreenState();
}

class _MobileProfileDetailScreenState extends State<MobileProfileDetailScreen>
    with ProfileDetailControllerState<MobileProfileDetailScreen> {
  final BlockService _blockService = BlockService();

  @override
  Widget build(BuildContext context) {
    if (!hasApiData) {
      return Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: const ProfileSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final profile = resolvedProfile;
    final images = (profile['images'] as List<dynamic>? ?? []);
    final bodyImages = images.length > 1 ? images.skip(1).toList() : [];

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(profile, images),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: _buildContent(profile, bodyImages),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildBackButton(),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ProfileActionBar(
            profile: profile,
            onReportPressed: () => ReportUserDialog.show(context, profile),
            onBlockPressed: () => _showBlockConfirmation(profile),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(Map<String, dynamic> profile, List<dynamic> images) {
    if (images.isEmpty) {
      return SizedBox(
        height: 500,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).primaryColorLight),
          child: const Center(
            child: Icon(LucideIcons.user, size: 84, color: Color(0xFFCCCCCC)),
          ),
        ),
      );
    }

    final firstImage = images.first;

    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        _ProfileAspectPhoto(
          image: firstImage,
          borderRadius: BorderRadius.zero,
          fallbackAspectRatio: 0.78,
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.78),
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
        if (firstImage is Map && firstImage['isBlurred'] == true)
          Center(child: _buildPrivacyOverlay(profile)),
        Positioned(
          left: 20,
          right: 20,
          bottom: 22,
          child: _HeroProfileInfo(profile: profile),
        ),
      ],
    );
  }

  Widget _buildContent(Map<String, dynamic> profile, List<dynamic> images) {
    final children = <Widget>[];
    int imageIndex = 0;

    if (_hasText(profile['bio'])) {
      children.add(_buildSectionTitle('About'));
      children.add(const SizedBox(height: 10));
      children.add(_buildAbout(profile['bio'].toString()));
      children.add(const SizedBox(height: 22));
    }

    if (imageIndex < images.length) {
      children.add(_buildInlinePhoto(images[imageIndex++]));
    }

    final basics = _basicItems(profile);
    if (basics.isNotEmpty) {
      children.add(_buildSectionTitle('The Basics'));
      children.add(const SizedBox(height: 12));
      children.add(_BasicsList(items: basics));
      children.add(const SizedBox(height: 26));
    }

    final career = _careerItems(profile);
    if (career.isNotEmpty) {
      children.add(_buildSectionTitle('Education & Career'));
      children.add(const SizedBox(height: 12));
      children.add(_CardGrid(items: career));
      children.add(const SizedBox(height: 22));
    }

    if (imageIndex < images.length) {
      children.add(_buildInlinePhoto(images[imageIndex++]));
    }

    final lifestyle = _lifestyleItems(profile);
    if (lifestyle.isNotEmpty) {
      children.add(_buildSectionTitle('Lifestyle'));
      children.add(const SizedBox(height: 12));
      children.add(_CardGrid(items: lifestyle, compact: true));
      children.add(const SizedBox(height: 26));
    }

    final languages = _languages(profile);
    if (languages.isNotEmpty) {
      children.add(_buildSectionTitle('Languages'));
      children.add(const SizedBox(height: 14));
      children.add(_LanguageChips(languages: languages));
      children.add(const SizedBox(height: 26));
    }

    final lookingFor = _lookingForText(profile);
    if (lookingFor != null) {
      children.add(_buildSectionTitle('Looking For'));
      children.add(const SizedBox(height: 12));
      children.add(_LookingForCard(text: lookingFor));
      children.add(const SizedBox(height: 22));
    }

    while (imageIndex < images.length) {
      children.add(_buildInlinePhoto(images[imageIndex++]));
    }

    children.add(SizedBox(height: 118 + MediaQuery.of(context).padding.bottom));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).primaryColor,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildAbout(String bio) {
    return Text(
      bio,
      style: TextStyle(
        color:
            Theme.of(context).textTheme.bodyLarge?.color ??
            AppColors.textPrimary,
        fontSize: 15,
        height: 1.55,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildInlinePhoto(dynamic image) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: _ProfileAspectPhoto(
        image: image,
        borderRadius: BorderRadius.circular(12),
        fallbackAspectRatio: 16 / 10,
      ),
    );
  }

  Widget _buildPrivacyOverlay(Map<String, dynamic> profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.lock, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            (profile['viewerPrivacyEnabled'] == true)
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
            (profile['viewerPrivacyEnabled'] == true)
                ? "You need access to see ${profile['name'] ?? 'this user'}'s photos."
                : "Request access to see ${profile['name'] ?? 'this user'}'s photos.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          RequestAccessButton(
            userId: profile['userId'],
            imageAccessRequestStatus: profile['imageAccessRequestStatus'],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      child: _CircleChromeButton(
        child: Icon(
          LucideIcons.chevron_left,
          size: 20,
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              AppColors.textPrimary,
        ),
        onTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
    );
  }

  void _showBlockConfirmation(Map<String, dynamic> profile) {
    BlockConfirmationBottomSheet.show(
      context: context,
      isBlocking: true,
      userName: profile['name'] ?? 'this user',
      onConfirm: () async {
        await _blockService.blockUser(profile['userId']);
      },
      onSuccess: () {
        final profileId = profile['id'] as int?;
        if (profileId != null) {
          context.read<MatchProvider>().removeProfile(profileId);
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
    );
  }

  List<_ProfileInfoItem> _basicItems(Map<String, dynamic> profile) {
    return [
      if (_hasText(profile['gender']))
        _ProfileInfoItem(
          icon: LucideIcons.heart,
          label: 'Gender',
          value: _formatEnum(profile['gender'].toString()),
        ),
      if (profile['heightCm'] != null)
        _ProfileInfoItem(
          icon: LucideIcons.ruler,
          label: 'Height',
          value: _formatHeight(profile['heightCm']),
        ),
      if (_hasText(profile['maritalStatus']))
        _ProfileInfoItem(
          icon: LucideIcons.users,
          label: 'Marital status',
          value: _formatEnum(profile['maritalStatus'].toString()),
        ),
      if (_hasText(profile['country']))
        _ProfileInfoItem(
          icon: LucideIcons.map_pin,
          label: 'Country',
          value: profile['country'].toString(),
        ),
      if (_hasText(profile['childrenStatus']))
        _ProfileInfoItem(
          icon: LucideIcons.baby,
          label: 'Children',
          value: _formatEnum(profile['childrenStatus'].toString()),
        ),
    ];
  }

  List<_ProfileInfoItem> _careerItems(Map<String, dynamic> profile) {
    return [
      if (_hasText(profile['highestEducation']))
        _ProfileInfoItem(
          icon: LucideIcons.graduation_cap,
          label: 'Education',
          value: _readableEducation(profile['highestEducation'].toString()),
        ),
      if (_hasText(profile['occupation']))
        _ProfileInfoItem(
          icon: LucideIcons.briefcase,
          label: 'Profession',
          value: profile['occupation'].toString(),
        ),
    ];
  }

  List<_ProfileInfoItem> _lifestyleItems(Map<String, dynamic> profile) {
    return [
      if (_hasText(profile['smokingHabit']))
        _ProfileInfoItem(
          icon: LucideIcons.cigarette,
          label: 'Smoking',
          value: _formatEnum(profile['smokingHabit'].toString()),
        ),
      if (_hasText(profile['drinkingHabit']))
        _ProfileInfoItem(
          icon: LucideIcons.glass_water,
          label: 'Drinking',
          value: _formatEnum(profile['drinkingHabit'].toString()),
        ),
    ];
  }

  List<String> _languages(Map<String, dynamic> profile) {
    final values = <String>[];
    final rawLanguages = profile['languages'];

    if (rawLanguages is List) {
      values.addAll(rawLanguages.whereType<String>());
    }

    if (_hasText(profile['motherTongue'])) {
      values.insert(0, profile['motherTongue'].toString());
    }

    final seen = <String>{};
    return values.where((value) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty || seen.contains(normalized)) return false;
      seen.add(normalized);
      return true;
    }).toList();
  }

  String? _lookingForText(Map<String, dynamic> profile) {
    final values = <String>[];
    if (_hasText(profile['lookingFor'])) {
      values.add(_formatEnum(profile['lookingFor'].toString()));
    }
    if (_hasText(profile['relationshipTimeline'])) {
      values.add(_formatEnum(profile['relationshipTimeline'].toString()));
    }
    if (values.isEmpty) return null;
    return values.join(' / ');
  }

  bool _hasText(dynamic value) => value != null && value.toString().isNotEmpty;

  String _formatHeight(dynamic rawCm) {
    final cm = rawCm is int
        ? rawCm
        : rawCm is num
        ? rawCm.toInt()
        : int.tryParse(rawCm.toString());

    if (cm == null || cm <= 0) return rawCm.toString();

    final feet = cm ~/ 30.48;
    final inches = ((cm % 30.48) / 2.54).round();
    return '$feet\'$inches" ($cm cm)';
  }

  String _readableEducation(String value) {
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
}

class _ProfileAspectPhoto extends StatelessWidget {
  final dynamic image;
  final BorderRadius borderRadius;
  final double fallbackAspectRatio;

  const _ProfileAspectPhoto({
    required this.image,
    required this.borderRadius,
    required this.fallbackAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedAppImage.fromProfileImageMap(
        image: image,
        width: double.infinity,
        fit: BoxFit.contain,
        imageBuilder: (context, imageProvider) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;

              return Image(
                image: imageProvider,
                width: width,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              );
            },
          );
        },
        placeholder: (context, url) =>
            _PhotoPlaceholder(aspectRatio: fallbackAspectRatio),
        errorWidget: (context, url, error) => _PhotoPlaceholder(
          aspectRatio: fallbackAspectRatio,
          icon: LucideIcons.image_off,
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final double aspectRatio;
  final IconData? icon;

  const _PhotoPlaceholder({required this.aspectRatio, this.icon});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight.withValues(alpha: 0.12),
        ),
        child: Center(
          child: icon == null
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : Icon(
                  icon,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
                ),
        ),
      ),
    );
  }
}

class _HeroProfileInfo extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _HeroProfileInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile['name']?.toString() ?? 'Unknown';
    final age = profile['age']?.toString();
    final title = (age == null || age.isEmpty) ? name : '$name, $age';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _MatchPill(percentage: profile['matchPercentage'] ?? 0),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
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
                    builder: (_) =>
                        VerifiedProfileBottomSheet(profileName: name),
                  );
                },
                child: Image.asset(
                  'assets/icons/verified_icon.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
            if (profile['isFoundingMember'] == true) ...[
              const SizedBox(width: 6),
              const FoundingMemberBadge(size: 20, isOverlay: true),
            ],
            if (profile['isBlocked'] == true) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.redAccent, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Blocked',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (profile['city'] != null || profile['state'] != null)
              _HeroMetaItem(
                icon: LucideIcons.map_pin,
                text: [
                  profile['city'],
                  profile['state'],
                ].where((value) => value != null).join(', '),
              ),
            if (profile['maritalStatus'] != null)
              _HeroMetaItem(
                icon: LucideIcons.heart,
                text: _formatEnum(profile['maritalStatus'].toString()),
              ),
            if (profile['lastLoginAt'] != null)
              _HeroMetaItem(
                icon: LucideIcons.circle,
                text: _formatLastLogin(profile['lastLoginAt'].toString()),
                iconColor: const Color(0xFF37C871),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroMetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _HeroMetaItem({required this.icon, required this.text, this.iconColor});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: icon == LucideIcons.circle ? 7 : 14,
          color: iconColor ?? Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MatchPill extends StatelessWidget {
  final dynamic percentage;

  const _MatchPill({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final pct = percentage is num
        ? percentage.round()
        : int.tryParse(percentage.toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        '$pct% Match',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CircleChromeButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _CircleChromeButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _BasicsList extends StatelessWidget {
  final List<_ProfileInfoItem> items;

  const _BasicsList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    item.label,
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (index != items.length - 1)
              Divider(
                height: 1,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.72),
              ),
          ],
        );
      }),
    );
  }
}

class _CardGrid extends StatelessWidget {
  final List<_ProfileInfoItem> items;
  final bool compact;

  const _CardGrid({required this.items, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (items.length == 1) {
      return _InfoCard(item: items.first, compact: compact);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: _InfoCard(item: items[i], compact: compact),
            ),
            if (i != items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final _ProfileInfoItem item;
  final bool compact;

  const _InfoCard({required this.item, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 68 : 92),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(item.icon, color: Theme.of(context).primaryColor, size: 20),
          SizedBox(height: compact ? 7 : 12),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  AppColors.textSecondary,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChips extends StatelessWidget {
  final List<String> languages;

  const _LanguageChips({required this.languages});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: languages.map((language) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.languages,
                color: Theme.of(context).primaryColor,
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                language,
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LookingForCard extends StatelessWidget {
  final String text;

  const _LookingForCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.heart,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

String _formatEnum(String value) {
  return value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((word) {
        if (word.isEmpty) return '';
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

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
    }
    return 'Active ${diff.inDays}d ago';
  } catch (_) {
    return '';
  }
}
