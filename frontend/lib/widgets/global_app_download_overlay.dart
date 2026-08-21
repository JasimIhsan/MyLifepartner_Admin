import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/services/app_download_promotion_service.dart';
import 'package:life_partner_again/screens/public_web/widgets/app_download_promotion.dart';

class GlobalAppDownloadOverlay extends StatefulWidget {
  const GlobalAppDownloadOverlay({super.key});

  @override
  State<GlobalAppDownloadOverlay> createState() =>
      _GlobalAppDownloadOverlayState();
}

class _GlobalAppDownloadOverlayState extends State<GlobalAppDownloadOverlay> {
  bool _isVisible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Only start timer and show the pop-up if running on the web
    if (kIsWeb) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleDismiss() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    return AppDownloadPromotion(
      visible: _isVisible,
      audience: AppDownloadPromotionService().audience,
      onDismiss: _handleDismiss,
    );
  }
}
