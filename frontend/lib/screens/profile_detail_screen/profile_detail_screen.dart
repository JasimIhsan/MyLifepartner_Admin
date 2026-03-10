import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/screens/home_screen/widgets/match_percentage_badge.dart';
import 'package:mylifepartner/screens/profile_detail_screen/widgets/profile_details_grid.dart';
import 'package:mylifepartner/services/match_service.dart';

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
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await MatchService.getProfileDetail(widget.profileId);
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _profile != null
                  ? _buildProfileContent()
                  : _buildNotFound(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Color(0xFF9E9E9E)),
          const SizedBox(height: 16),
          Text(
            'Failed to load profile',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Text(
        'Profile not found',
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final p = _profile!;
    final images = (p['images'] as List<dynamic>? ?? []);
    final highlights =
        (p['compatibilityHighlights'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    return CustomScrollView(
      slivers: [
        _buildImageHeader(images),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildNameSection(p),
                const SizedBox(height: 16),
                if (highlights.isNotEmpty) ...[
                  _buildCompatibilitySection(highlights),
                  const SizedBox(height: 16),
                ],
                if (p['bio'] != null && (p['bio'] as String).isNotEmpty) ...[
                  _buildBioSection(p['bio']),
                  const SizedBox(height: 16),
                ],
                ProfileDetailsGrid(profile: p),
                const SizedBox(height: 16),
                if (images.length > 1) ...[
                  _buildAllPhotosSection(images),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageHeader(List<dynamic> images) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppColors.background,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: images.isNotEmpty
            ? _ImageCarousel(images: images)
            : Container(
                color: AppColors.primaryLight,
                child: const Center(
                  child: Icon(Icons.person_rounded, size: 80,
                      color: AppColors.primary),
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildNameSection(Map<String, dynamic> p) {
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
                ),
              ),
              if (p['city'] != null || p['state'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
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
        MatchPercentageBadge(percentage: p['matchPercentage'] ?? 0),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildCompatibilitySection(List<String> highlights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compatibility',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: highlights.map((h) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B57).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2E8B57).withValues(alpha: 0.20),
                ),
              ),
              child: Text(
                h,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF1A6B3A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 100.ms);
  }

  Widget _buildBioSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            bio,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 150.ms);
  }

  Widget _buildAllPhotosSection(List<dynamic> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (${images.length})',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final img = images[index] as Map<String, dynamic>;
            final url = img['imageUrl'] as String?;
            return GestureDetector(
              onTap: () => _showFullImage(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: url != null
                    ? Image.network(url, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder())
                    : _imagePlaceholder(),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 350.ms, delay: 250.ms);
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(Icons.image_rounded, size: 40, color: AppColors.primary),
      ),
    );
  }

  void _showFullImage(BuildContext context, String? url) {
    if (url == null) return;
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
}

// ─── Image carousel for the header ──────────────────────────────────────────

class _ImageCarousel extends StatefulWidget {
  final List<dynamic> images;

  const _ImageCarousel({required this.images});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, index) {
            final img = widget.images[index] as Map<String, dynamic>;
            final url = img['imageUrl'] as String?;
            return url != null
                ? Image.network(url, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 48,
                            color: AppColors.primary),
                      ),
                    ),
                  )
                : Container(color: AppColors.primaryLight);
          },
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
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
