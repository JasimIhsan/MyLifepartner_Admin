import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/services/app_download_promotion_service.dart';
import 'package:life_partner_again/screens/public_web/widgets/app_download_promotion.dart';
import 'package:life_partner_again/screens/public_web/widgets/public_web_footer.dart';
import 'package:life_partner_again/screens/public_web/widgets/public_web_navbar.dart';

class PublicWebLayout extends StatefulWidget {
  final String currentRoute;
  final Widget child;
  final bool showGlobalDownloadCta;

  const PublicWebLayout({
    super.key,
    required this.currentRoute,
    required this.child,
    this.showGlobalDownloadCta = true,
  });

  @override
  State<PublicWebLayout> createState() => _PublicWebLayoutState();
}

class _PublicWebLayoutState extends State<PublicWebLayout> {
  final ScrollController _scrollController = ScrollController();
  final AppDownloadPromotionService _promotionService =
      AppDownloadPromotionService();
  Timer? _promotionTimer;
  bool _showPromotion = false;
  bool _isCheckingPromotion = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _promotionTimer = Timer(
      AppPromotionConfig.initialDelay,
      () => _tryShowPromotion(),
    );
  }

  @override
  void dispose() {
    _promotionTimer?.cancel();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final nextIsScrolled = _scrollController.offset > 10;
    if (nextIsScrolled != _isScrolled && mounted) {
      setState(() => _isScrolled = nextIsScrolled);
    }

    if (_scrollController.offset >= AppPromotionConfig.meaningfulScrollOffset) {
      _tryShowPromotion();
    }
  }

  Future<void> _tryShowPromotion() async {
    if (_showPromotion || _isCheckingPromotion || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    _isCheckingPromotion = true;
    final canShow = await _promotionService.canShowPromotion();
    _isCheckingPromotion = false;

    if (!mounted || !canShow) return;
    await _promotionService.recordShown();
    if (!mounted) return;
    setState(() => _showPromotion = true);
  }

  Future<void> _dismissPromotion() async {
    await _promotionService.recordDismissed();
    if (!mounted) return;
    setState(() => _showPromotion = false);
  }

  @override
  Widget build(BuildContext context) {
    final title = PublicWebRoutes.titleFor(widget.currentRoute);

    return Title(
      color: Theme.of(context).colorScheme.primary,
      title: title,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  PublicWebNavbar(
                    currentRoute: widget.currentRoute,
                    isScrolled: _isScrolled,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        children: [
                          widget.child,
                          if (widget.showGlobalDownloadCta)
                            const PublicDownloadCtaSection(),
                          const PublicWebFooter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              AppDownloadPromotion(
                visible: _showPromotion,
                audience: _promotionService.audience,
                onDismiss: _dismissPromotion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
