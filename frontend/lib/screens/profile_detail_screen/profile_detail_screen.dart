import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/match_recommendation.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/profile_detail_screen/widgets/profile_details_grid.dart';
import 'package:mylifepartner/services/match_service.dart';
import 'package:provider/provider.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int profileId;
  final String profileName;

  /// Passed from the listing so the page can render immediately (hack fix).
  final MatchRecommendation? seedProfile;

  const ProfileDetailScreen({
    super.key,
    required this.profileId,
    required this.profileName,
    this.seedProfile,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  // Full API data (enriched – may arrive later)
  Map<String, dynamic>? _apiProfile;

  @override
  void initState() {
    super.initState();
    _enrichFromApi();
  }

  /// Tries to fetch full profile from API in background.
  /// The seed profile is shown immediately while this runs.
  Future<void> _enrichFromApi() async {
    try {
      final data = await MatchService.getProfileDetail(widget.profileId);
      if (mounted && data != null) {
        setState(() => _apiProfile = data);
      }
    } catch (_) {
      // Silently swallow – seed data is enough for now.
    }
  }

  // ─── Resolve helpers (prefer API data, fall back to seed) ─────────────────

  Map<String, dynamic> get _resolvedProfile {
    if (_apiProfile != null) return _apiProfile!;
    final s = widget.seedProfile;
    if (s == null) return {};
    return {
      'id': s.id,
      'name': s.name,
      'age': s.age,
      'city': s.city,
      'religion': s.religion,
      'occupation': s.occupation,
      'heightCm': s.heightCm,
      'matchPercentage': s.matchPercentage,
      'compatibilityHighlights': s.compatibilityHighlights,
      'images': s.images
          .map((img) => {
                'imageUrl': img.imageUrl,
                'isPrimary': img.isPrimary,
              })
          .toList(),
    };
  }

  bool get _hasSeedOrApi =>
      widget.seedProfile != null || _apiProfile != null;

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_hasSeedOrApi) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = _resolvedProfile;
    final images = (p['images'] as List<dynamic>? ?? []);
    final highlights =
        (p['compatibilityHighlights'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          slivers: [
            _buildSliverHeader(images),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    _buildNameRow(p),
                    const SizedBox(height: 18),
                    if (highlights.isNotEmpty) ...[
                      _buildSectionLabel('Compatibility'),
                      const SizedBox(height: 10),
                      _buildHighlights(highlights),
                      const SizedBox(height: 20),
                    ],
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
                      _buildSectionLabel(
                          'Photos (${images.length})'),
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

        // Fixed bottom action bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildActionBar(),
        ),
      ],
    );
  }

  // ─── Header (image carousel as sliver) ────────────────────────────────────

  Widget _buildSliverHeader(List<dynamic> images) {
    return SliverAppBar(
      expandedHeight: 420,
      pinned: false,
      snap: false,
      floating: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? _HeaderCarousel(images: images)
            : Container(
                color: AppColors.primaryLight,
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 80,
                    color: Color(0xFFCCCCCC),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
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

  Widget _buildNameRow(Map<String, dynamic> p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p['name'] ?? 'Unknown'}, ${p['age'] ?? ''}',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (p['city'] != null || p['state'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        [p['city'], p['state']]
                            .where((e) => e != null)
                            .join(', '),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _buildMatchBadge(p['matchPercentage'] ?? 0),
      ],
    ).animate().fadeIn(duration: 300.ms);
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
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'match',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sections ──────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        bio,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }



  // ─── Bottom action bar ─────────────────────────────────────────────────────

  Widget _buildActionBar() {
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
            onTap: () async {
              try {
                await context.read<MatchProvider>().swipeLeft();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          context.read<MatchProvider>().error ?? 'Action failed'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 12),
          _actionButton(
            label: 'Interested',
            icon: Icons.favorite_rounded,
            isOutlined: false,
            onTap: () async {
              try {
                await context.read<MatchProvider>().swipeRight();
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          context.read<MatchProvider>().error ?? 'Action failed'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool isOutlined,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.white : AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            border: isOutlined
                ? Border.all(color: const Color(0xFFDDDDDD), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOutlined ? AppColors.textPrimary : Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isOutlined ? AppColors.textPrimary : Colors.white,
                ),
              ),
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
                style: GoogleFonts.poppins(
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
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final img = widget.images[i] as Map<String, dynamic>;
            final url = img['imageUrl'] as String?;
            return url != null
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                    ),
                  )
                : Container(color: AppColors.primaryLight);
          },
        ),
        // Gradient overlay at bottom for readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Dot indicators
        if (widget.images.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _page == i ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _page == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
