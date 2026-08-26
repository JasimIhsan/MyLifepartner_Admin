import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/discovery_filter.dart';
import 'package:life_partner_again/providers/discovery_provider.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:life_partner_again/widgets/verified_icon.dart';
import 'package:provider/provider.dart';

class WebSearchScreen extends StatefulWidget {
  const WebSearchScreen({super.key});

  @override
  State<WebSearchScreen> createState() => _WebSearchScreenState();
}

class _WebSearchScreenState extends State<WebSearchScreen> {
  final ScrollController _scrollController = ScrollController();

  late DiscoveryFilter _filter;
  RangeValues _ageRange = const RangeValues(18, 60);
  bool _isFiltersExpanded = false;

  final List<String> _maritalOptions = [
    'AWAITING_DIVORCE',
    'DIVORCED',
    'WIDOWED',
    'SEPARATED',
    'NEVER_MARRIED',
  ];

  final List<String> _smokingOptions = [
    'NEVER',
    'OCCASIONALLY',
    'SOCIALLY',
    'REGULARLY',
  ];

  final List<String> _drinkingOptions = [
    'NEVER',
    'OCCASIONALLY',
    'SOCIALLY',
    'REGULARLY',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize filters from provider
    _filter = context.read<DiscoveryProvider>().filter.copyWith();
    if (_filter.ageFrom != null && _filter.ageTo != null) {
      _ageRange = RangeValues(
        _filter.ageFrom!.toDouble(),
        _filter.ageTo!.toDouble(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<DiscoveryProvider>().profiles.isEmpty) {
        context.read<DiscoveryProvider>().refresh();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!context.read<DiscoveryProvider>().isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<DiscoveryProvider>().loadMore();
    }
  }

  void _applyFilters() {
    _filter.ageFrom = _ageRange.start.round();
    _filter.ageTo = _ageRange.end.round();
    _filter.searchQuery = null;
    context.read<DiscoveryProvider>().applyFilter(_filter);

    // Auto-collapse after applying on success, optionally
    setState(() {
      _isFiltersExpanded = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _filter = DiscoveryFilter();
      _ageRange = const RangeValues(18, 60);
    });
    context.read<DiscoveryProvider>().resetFilter();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildChips(
    List<String> options,
    List<String> selected,
    Function(String) onSelect,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(
            option.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onSelect(option),
          selectedColor: Theme.of(context).primaryColor,
          checkmarkColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
            ),
          ),
          backgroundColor: Theme.of(context).cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        );
      }).toList(),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.only(left: 32.0, right: 32.0, top: 16.0),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Advanced Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset All'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1: Age
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Age Range'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_ageRange.start.round()} years'),
                        Text('${_ageRange.end.round()} years'),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 80,
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                      onChanged: (values) {
                        setState(() {
                          _ageRange = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              // Column 2: Marital Status
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Marital Status'),
                    _buildChips(_maritalOptions, _filter.maritalStatuses, (
                      val,
                    ) {
                      setState(() {
                        if (_filter.maritalStatuses.contains(val)) {
                          _filter.maritalStatuses.remove(val);
                        } else {
                          _filter.maritalStatuses.add(val);
                        }
                      });
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 48),
              // Column 3: Habits
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Smoking Habit'),
                    _buildChips(_smokingOptions, _filter.smokingStatuses, (
                      val,
                    ) {
                      setState(() {
                        if (_filter.smokingStatuses.contains(val)) {
                          _filter.smokingStatuses.remove(val);
                        } else {
                          _filter.smokingStatuses.add(val);
                        }
                      });
                    }),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Drinking Habit'),
                    _buildChips(_drinkingOptions, _filter.drinkingStatuses, (
                      val,
                    ) {
                      setState(() {
                        if (_filter.drinkingStatuses.contains(val)) {
                          _filter.drinkingStatuses.remove(val);
                        } else {
                          _filter.drinkingStatuses.add(val);
                        }
                      });
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 200,
              child: CustomButton(
                text: 'Apply Filters',
                onPressed: _applyFilters,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(32.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 280.0,
          childAspectRatio: 0.75,
          crossAxisSpacing: 24.0,
          mainAxisSpacing: 24.0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1200.ms,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              );
        }, childCount: 10),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No profiles found',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters to see more results.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear Filters',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(dynamic profile) {
    final primaryImage = profile.primaryOrFirstImage;
    final avatarId = primaryImage?.imageId;
    final avatarUrl = primaryImage?.presignedImageUrl;
    final hasImages = profile.images.isNotEmpty;

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.profileDetailPath(profile.id));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: hasImages && avatarId != null
                  ? CachedAppImage(
                      imageId: avatarId,
                      presignedImageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${profile.name ?? 'Unknown'}, ${profile.age ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (profile.isVerified == true) ...[
                        const SizedBox(width: 4),
                        const VerifiedIconWidget(isVerified: true, size: 20),
                      ],
                      if (profile.isFoundingMember == true) ...[
                        const SizedBox(width: 4),
                        const FoundingMemberBadge(size: 20),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${profile.city ?? 'Unknown City'}, ${profile.state ?? ''}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.work_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile.occupation ?? 'Not specified',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        size: 64,
        color: Theme.of(context).disabledColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 64.0),
        child: Consumer<DiscoveryProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Filters Toggle
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          32.0,
                          48.0,
                          32.0,
                          24.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Search Profiles',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Find your perfect match. Use advanced filters to narrow down your preferences.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isFiltersExpanded = !_isFiltersExpanded;
                                });
                              },
                              icon: Icon(
                                _isFiltersExpanded
                                    ? Icons.tune_rounded
                                    : Icons.tune_rounded,
                              ),
                              label: const Text(
                                'Advanced Filters',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                side: BorderSide(
                                  color: _isFiltersExpanded
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).dividerColor,
                                  width: _isFiltersExpanded ? 2 : 1,
                                ),
                                foregroundColor: _isFiltersExpanded
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Collapsible Filters Area
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        child: _isFiltersExpanded
                            ? _buildFiltersPanel()
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
                // Results Grid
                if (provider.state == DiscoveryState.loading &&
                    provider.profiles.isEmpty)
                  _buildSkeletonGrid()
                else if (provider.profiles.isEmpty)
                  _buildEmptyState()
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(32.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 280.0,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 24.0,
                            mainAxisSpacing: 24.0,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final profile = provider.profiles[index];
                        return _buildProfileCard(profile);
                      }, childCount: provider.profiles.length),
                    ),
                  ),
                if (provider.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
