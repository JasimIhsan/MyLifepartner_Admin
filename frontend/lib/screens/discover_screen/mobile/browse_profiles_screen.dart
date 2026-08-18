import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/providers/discovery_provider.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';
import 'package:life_partner_again/widgets/verified_icon.dart';
import 'package:life_partner_again/widgets/custom_popover_tooltip.dart';
import 'package:life_partner_again/widgets/founding_member_badge.dart';
import 'package:provider/provider.dart';

import 'advanced_search_screen.dart';

class BrowseProfilesScreen extends StatefulWidget {
  const BrowseProfilesScreen({super.key});

  @override
  State<BrowseProfilesScreen> createState() => _BrowseProfilesScreenState();
}

class _BrowseProfilesScreenState extends State<BrowseProfilesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<DiscoveryProvider>().profiles.isEmpty) {
        context.read<DiscoveryProvider>().refresh();
      }
      _searchController.text =
          context.read<DiscoveryProvider>().filter.searchQuery ?? '';
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // void _onSearchChanged(String query) {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 500), () {
  //     final provider = context.read<DiscoveryProvider>();
  //     final filter = provider.filter.copyWith(searchQuery: query);
  //     provider.applyFilter(filter);
  //   });
  // }

  void _onScroll() {
    if (!context.read<DiscoveryProvider>().isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      context.read<DiscoveryProvider>().loadMore();
    }
  }

  Widget _buildSkeletonGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1200.ms,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
              );
        }, childCount: 6),
      ),
    );
  }

  Widget _profileImagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        size: 48,
        color: Theme.of(context).disabledColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: const Text(
          'Browse Profiles',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color:
                    Theme.of(context).iconTheme.color ??
                    Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvancedSearchScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<DiscoveryProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.refresh(clearProfiles: false),
            color: Theme.of(context).primaryColor,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // SliverToBoxAdapter(
                //   child: Padding(
                //     padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                //     child: TextField(
                //       controller: _searchController,
                //       style: const TextStyle(fontSize: 16),
                //       decoration: InputDecoration(
                //         hintText: 'Search by name...',
                //         hintStyle: TextStyle(
                //           color: Theme.of(context).hintColor,
                //           fontSize: 15,
                //         ),
                //         prefixIcon: Icon(
                //           Icons.search_rounded,
                //           color:
                //               Theme.of(
                //                 context,
                //               ).iconTheme.color?.withValues(alpha: 0.5) ??
                //               Colors.grey.shade400,
                //           size: 22,
                //         ),
                //         suffixIcon: _searchController.text.isNotEmpty
                //             ? IconButton(
                //                 icon: Icon(
                //                   Icons.cancel_rounded,
                //                   color:
                //                       Theme.of(context).iconTheme.color
                //                           ?.withValues(alpha: 0.5) ??
                //                       Colors.grey.shade400,
                //                   size: 20,
                //                 ),
                //                 onPressed: () {
                //                   _searchController.clear();
                //                   _onSearchChanged('');
                //                   setState(() {});
                //                 },
                //               )
                //             : null,
                //         filled: true,
                //         fillColor: Theme.of(context).cardColor,
                //         contentPadding: const EdgeInsets.symmetric(
                //           vertical: 14,
                //         ),
                //         border: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(16),
                //           borderSide: BorderSide(
                //             color: Theme.of(context).dividerColor,
                //           ),
                //         ),
                //         enabledBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(16),
                //           borderSide: BorderSide(
                //             color: Theme.of(context).dividerColor,
                //           ),
                //         ),
                //         focusedBorder: OutlineInputBorder(
                //           borderRadius: BorderRadius.circular(16),
                //           borderSide: BorderSide(
                //             color: Theme.of(context).primaryColor,
                //             width: 1.5,
                //           ),
                //         ),
                //       ),
                //       onChanged: (val) {
                //         setState(() {});
                //         _onSearchChanged(val);
                //       },
                //     ),
                //   ),
                // ),
                if (provider.state == DiscoveryState.loading &&
                    provider.profiles.isEmpty)
                  _buildSkeletonGrid()
                else if (provider.state == DiscoveryState.error &&
                    provider.profiles.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error ?? 'Something went wrong',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => provider.refresh(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (provider.profiles.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No profiles found',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color ??
                                  Colors.grey.shade800,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color ??
                                  Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final profile = provider.profiles[index];
                        final primaryImage = profile.primaryOrFirstImage;

                        return GestureDetector(
                          onTap: () {
                            context.push(
                              AppRoutes.profileDetailPath(profile.id),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).shadowColor.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background Image
                                if (primaryImage != null)
                                  CachedAppImage(
                                    imageId: primaryImage.imageId,
                                    presignedImageUrl:
                                        primaryImage.presignedImageUrl,
                                    isBlurred: primaryImage.isBlurred,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        _profileImagePlaceholder(context),
                                    errorWidget: (_, __, ___) =>
                                        _profileImagePlaceholder(context),
                                  )
                                else
                                  _profileImagePlaceholder(context),

                                // Premium Gradient Overlay
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.9),
                                          Colors.black.withValues(alpha: 0.4),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.1),
                                        ],
                                        stops: const [0.0, 0.4, 0.7, 1.0],
                                      ),
                                    ),
                                  ),
                                ),

                                // Profile Details
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Name, Age & Verified
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                '${profile.name}, ${profile.age}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: -0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (profile.isVerified || profile.isPremium || profile.isFoundingMember) ...[
                                              const SizedBox(width: 4),
                                              CustomPopoverTooltip(
                                                title: 'Verified Profile',
                                                description:
                                                    'This profile has been verified and authenticated by our moderation team.',
                                                child: VerifiedIconWidget(
                                                  isVerified: profile.isVerified,
                                                  isFoundingMember: profile.isFoundingMember,
                                                  isPremium: profile.isPremium,
                                                  size: 16,
                                                ),
                                              ),
                                            ],
                                            if (profile.isFoundingMember) ...[
                                              const SizedBox(width: 4),
                                              const FoundingMemberBadge(
                                                size: 16,
                                                isOverlay: true,
                                              ),
                                            ],
                                          ],
                                        ),

                                        // Profession / Occupation
                                        if (profile.occupation != null &&
                                            profile.occupation!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            profile.occupation!,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],

                                        // Location
                                        if (profile.city != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                color: Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  profile.state != null
                                                      ? '${profile.city}, ${profile.state}'
                                                      : profile.city!,
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: provider.profiles.length),
                    ),
                  ),
                if (provider.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
