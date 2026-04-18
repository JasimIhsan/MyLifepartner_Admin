import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/chat_screen/chat_screen.dart';
import 'package:mylifepartner/screens/profile_detail_screen/widgets/interest_limit_bottom_sheet.dart';
import 'package:mylifepartner/screens/profile_detail_screen/widgets/profile_details_grid.dart';
import 'package:mylifepartner/services/match_service.dart';
import 'package:mylifepartner/shared/widgets/verified_profile_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:country_flags/country_flags.dart';
import 'package:mylifepartner/core/country_helper.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int profileId;
  final String profileName;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  // Full API data (enriched – may arrive later)
  Map<String, dynamic>? _apiProfile;

  bool _isPassing = false;
  bool _isInterested = false;

  @override
  void initState() {
    super.initState();
    _enrichFromApi();
  }

  /// Fetches full profile from API.
  Future<void> _enrichFromApi() async {
    try {
      final data = await MatchService.getProfileDetail(widget.profileId);
      if (mounted && data != null) {
        setState(() => _apiProfile = data);
      }
    } catch (_) {
      // Handle error gracefully
    }
  }

  // ─── Resolve helpers ────────────────────────────────────────────────────────

  Map<String, dynamic> get _resolvedProfile {
    return _apiProfile ?? {};
  }

  bool get _hasApiData => _apiProfile != null;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_hasApiData) {
      return Scaffold(
        backgroundColor: AppColors.textWhite,
        body: _buildSkeleton(),
      );
    }

    return Scaffold(backgroundColor: AppColors.textWhite, body: _buildBody());
  }

  Widget _buildSkeleton() {
    final double actionBarAndGapHeight =
        90 + MediaQuery.of(context).padding.bottom;
    final double topSectionHeight =
        MediaQuery.of(context).size.height - actionBarAndGapHeight;

    return Stack(
      children: [
        // Scrollable skeleton (same structure as real UI)
        CustomScrollView(
          slivers: [
            // 🔝 HEADER (same as real)
            SliverToBoxAdapter(
              child: SizedBox(
                height: topSectionHeight,
                child: Stack(
                  children: [
                    // Image placeholder
                    Positioned.fill(
                      child: Container(color: Colors.grey.shade300),
                    ),

                    // Gradient overlay (same as real)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 250,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Name row skeleton
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _skeletonBox(width: 180, height: 28),
                                const SizedBox(height: 8),
                                _skeletonBox(width: 120, height: 16),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _skeletonBox(width: 60, height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 🔽 BODY (same spacing & structure)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compatibility section
                    _skeletonBox(width: 120, height: 18),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(
                        4,
                        (_) => _skeletonBox(width: 80, height: 28),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // About section
                    _skeletonBox(width: 100, height: 18),
                    const SizedBox(height: 12),
                    _skeletonBox(height: 80),

                    const SizedBox(height: 24),

                    // Details grid placeholder
                    _skeletonBox(height: 120),

                    const SizedBox(height: 24),

                    // Photos section
                    _skeletonBox(width: 140, height: 18),
                    const SizedBox(height: 12),
                    _skeletonBox(height: 260),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // 🔙 Back button (same position)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _skeletonCircle(44),
        ),

        // 🌍 Flag placeholder
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: _skeletonCircle(38),
        ),

        // ⬇️ Bottom action bar skeleton
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: _skeletonBox(height: 50)),
                const SizedBox(width: 12),
                Expanded(child: _skeletonBox(height: 50)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _skeletonCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _skeletonBox({double width = double.infinity, double height = 16}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildBody() {
    final p = _resolvedProfile;
    final images = (p['images'] as List<dynamic>? ?? []);
    final highlights = (p['compatibilityHighlights'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // The action bar is roughly 90px + safe area bottom.
    // Making the top section take (ScreenHeight - 90 - safeArea) guarantees
    // the name row sits perfectly above the action bar, and the image fills the rest (up to ~80% of screen).
    final double actionBarAndGapHeight =
        90 + MediaQuery.of(context).padding.bottom;
    final double topSectionHeight =
        MediaQuery.of(context).size.height - actionBarAndGapHeight;

    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: topSectionHeight,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildHeaderCarousel(images)),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: _buildNameRow(p, isOverlay: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //if (highlights.isNotEmpty) ...[
                    //_buildSectionLabel('Compatibility'),
                    //const SizedBox(height: 10),
                    // _buildHighlights(highlights),
                    //  const SizedBox(height: 20),
                    //],
                    if (p['bio'] != null &&
                        (p['bio'] as String).isNotEmpty) ...[
                      _buildSectionLabel('About'),
                      const SizedBox(height: 10),
                      _buildBio(p['bio']),
                      const SizedBox(height: 20),
                    ],
                    ProfileDetailsGrid(profile: p),
                    const SizedBox(height: 20),
                    if (images.isNotEmpty) ...[
                      _buildSectionLabel('Photos (${images.length})'),
                      const SizedBox(height: 12),
                      _BodyPhotoCarousel(images: images),
                      const SizedBox(height: 20),
                    ],
                    // Space for fixed bottom bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Floating back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: _buildBackButton(),
        ),

        // Floating country flag
        if (p['country'] != null && CountryHelper.getCode(p['country']) != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: CountryFlag.fromCountryCode(
                  CountryHelper.getCode(p['country'])!,
                  width: 38,
                  height: 38,
                ),
              ),
            ),
          ),

        // Fixed bottom action bar
        Positioned(bottom: 0, left: 0, right: 0, child: _buildActionBar(p)),
      ],
    );
  }

  // ─── Header (image carousel as sliver) ────────────────────────────────────

  Widget _buildHeaderCarousel(List<dynamic> images) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(Icons.person_rounded, size: 80, color: Color(0xFFCCCCCC)),
        ),
      );
    }

    return _HeaderCarousel(images: images);
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ─── Name / match row ──────────────────────────────────────────────────────

  Widget _buildNameRow(Map<String, dynamic> p, {bool isOverlay = false}) {
    final textColor = isOverlay ? Colors.white : AppColors.textPrimary;
    final subTextColor = isOverlay
        ? Colors.white.withValues(alpha: 0.9)
        : AppColors.textSecondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// LEFT SIDE (flexible)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 Name + age + verified
              Row(
                children: [
                  /// NAME + AGE (flexible, prevents overflow)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p['name'] ?? 'Unknown',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 28, // reduced from 32 (important)
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p['age'] ?? ''}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// VERIFIED BADGE
                  if (p['isVerified'] == true) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) => VerifiedProfileBottomSheet(
                            profileName: p['name'] ?? 'Unknown',
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/icons/verified_icon.png',
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ],
                ],
              ),

              /// 🔹 META (marital status + location + last seen) → WRAPS instead of overflow
              if (p['maritalStatus'] != null ||
                  p['city'] != null ||
                  p['state'] != null ||
                  p['lastLoginAt'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      /// MARITAL STATUS
                      if (p['maritalStatus'] != null)
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
                              _formatEnum(p['maritalStatus']),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ),

                      /// LOCATION
                      if (p['city'] != null || p['state'] != null)
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
                                  p['city'],
                                  p['state'],
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

                      /// LAST SEEN (Access time)
                      if (p['lastLoginAt'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: subTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatLastLogin(p['lastLoginAt'].toString()),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: subTextColor,
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

        /// RIGHT SIDE (fixed)
        _buildMatchBadge(p['matchPercentage'] ?? 0),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text('match', style: TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  // ─── Sections ──────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildHighlights(List<String> highlights) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: highlights.map((h) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            h,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(duration: 300.ms, delay: 80.ms);
  }

  Widget _buildBio(String bio) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        bio,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  // ─── Bottom action bar ─────────────────────────────────────────────────────

  Widget _buildActionBar(Map<String, dynamic> p) {
    final interactionStateRaw = p['interactionState'];
    InteractionState state = InteractionState.none;
    if (interactionStateRaw is InteractionState) {
      state = interactionStateRaw;
    } else if (interactionStateRaw is String) {
      state = InteractionState.fromString(interactionStateRaw);
    }
    final bool isMatched = state == InteractionState.matched;
    final bool isInterestSent = state == InteractionState.interestSent;
    final bool isInterestReceived = state == InteractionState.interestReceived;
    final bool isNone = state == InteractionState.none;

    final bool canPass = isNone || isInterestReceived;
    final bool canAction = isNone || isInterestReceived || isMatched;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _actionButton(
            label: 'Pass',
            icon: Icons.close_rounded,
            isOutlined: true,
            isLoading: _isPassing,
            onTap: canPass
                ? () async {
                    if (_isPassing || _isInterested) return;
                    setState(() => _isPassing = true);
                    try {
                      await context.read<MatchProvider>().swipeLeft(
                        targetProfileId: p['id'],
                      );
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        if (e is DioException &&
                            e.response?.statusCode == 402) {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => InterestLimitBottomSheet(
                              message:
                                  e.response?.data?['message'] ??
                                  'Unable to process skip at this moment.',
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.read<MatchProvider>().error ??
                                    'Failed to skip',
                              ),
                            ),
                          );
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _isPassing = false);
                    }
                  }
                : null,
          ),
          const SizedBox(width: 12),
          _actionButton(
            label: _getInteractionLabel(state),
            icon: _getInteractionIcon(state),
            isOutlined: false,
            isLoading: _isInterested,
            isDisabled: !canAction || isInterestSent,
            onTap: canAction && !isInterestSent
                ? () async {
                    if (_isPassing || _isInterested) return;

                    // If already matched, navigate to chat
                    if (isMatched) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatPlaceholderScreen(),
                        ),
                      );
                      return;
                    }

                    setState(() => _isInterested = true);
                    try {
                      await context.read<MatchProvider>().swipeRight(
                        targetProfileId: p['id'],
                      );
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        if (e is DioException &&
                            e.response?.statusCode == 402) {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (_) => InterestLimitBottomSheet(
                              message:
                                  e.response?.data?['message'] ??
                                  'Unable to send interest at this moment.',
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.read<MatchProvider>().error ??
                                    'Failed to send interest',
                              ),
                            ),
                          );
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _isInterested = false);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  String _getInteractionLabel(InteractionState state) {
    switch (state) {
      case InteractionState.none:
        return 'Send Interest';
      case InteractionState.interestSent:
        return 'Interest Sent';
      case InteractionState.interestReceived:
        return 'Accept';
      case InteractionState.matched:
        return 'Chat';
    }
  }

  IconData _getInteractionIcon(InteractionState state) {
    switch (state) {
      case InteractionState.none:
        return Icons.favorite_rounded;
      case InteractionState.interestSent:
        return Icons.send_rounded;
      case InteractionState.interestReceived:
        return Icons.check_circle_rounded;
      case InteractionState.matched:
        return Icons.chat_bubble_rounded;
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool isOutlined,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    final bool effectivelyDisabled = isDisabled || onTap == null;
    return Expanded(
      child: GestureDetector(
        onTap: isLoading || effectivelyDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isOutlined
                ? Colors.white
                : effectivelyDisabled
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            border: isOutlined
                ? Border.all(
                    color: effectivelyDisabled
                        ? Colors.grey.shade200
                        : Colors.grey.shade300,
                    width: 1.5,
                  )
                : null,
            boxShadow: !isOutlined && !effectivelyDisabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isOutlined ? AppColors.textPrimary : Colors.white,
                  ),
                )
              else ...[
                Icon(
                  icon,
                  size: 18,
                  color: isOutlined
                      ? (effectivelyDisabled
                            ? AppColors.textSecondary.withValues(alpha: 0.5)
                            : AppColors.textPrimary)
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isOutlined
                        ? (effectivelyDisabled
                              ? AppColors.textSecondary.withValues(alpha: 0.5)
                              : AppColors.textPrimary)
                        : Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Body photo carousel ───────────────────────────────────────────────────

class _BodyPhotoCarousel extends StatefulWidget {
  final List<dynamic> images;

  const _BodyPhotoCarousel({required this.images});

  @override
  State<_BodyPhotoCarousel> createState() => _BodyPhotoCarouselState();
}

class _BodyPhotoCarouselState extends State<_BodyPhotoCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carousel
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 260,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) {
                final img = widget.images[i] as Map<String, dynamic>;
                final url = img['imageUrl'] as String?;
                return GestureDetector(
                  onTap: url != null ? () => _showFullImage(url) : null,
                  child: url != null
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryLight,
                            child: const Center(
                              child: Icon(
                                Icons.image_rounded,
                                size: 40,
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 40,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 10),
          // Dot indicators + counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(widget.images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _page == i ? 20 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _page == i
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              const SizedBox(width: 10),
              Text(
                '${_page + 1} / ${widget.images.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Header image carousel ─────────────────────────────────────────────────

class _HeaderCarousel extends StatefulWidget {
  final List<dynamic> images;

  const _HeaderCarousel({required this.images});

  @override
  State<_HeaderCarousel> createState() => _HeaderCarouselState();
}

class _HeaderCarouselState extends State<_HeaderCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final img = images[i] as Map<String, dynamic>;
            final url = img['imageUrl'] as String?;
            if (url == null) return Container(color: AppColors.primaryLight);

            return Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.primaryLight),
            );
          },
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ),
        // Indicators
        if (images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _page == i ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _page == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
