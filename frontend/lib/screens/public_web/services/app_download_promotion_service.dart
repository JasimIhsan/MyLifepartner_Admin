import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppPromotionConfig {
  static const Duration initialDelay = Duration(seconds: 25);
  static const Duration dismissCooldown = Duration(days: 7);
  static const Duration downloadClickCooldown = Duration(days: 30);
  static const double meaningfulScrollOffset = 560;
}

class AppStoreLinks {
  static const String androidPackageId =
      'com.premiumglobalcorp.lifepartneragain';
  static const String playStore =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  // Add the numeric App Store URL here when the production listing is available.
  static const String? appStore = null;

  static const String supportEmail = 'support@mylifepartner.com';
  static const String? supportPhone = null;
  static const String? businessName = null;
}

enum AppDownloadStore { appStore, playStore }

enum AppDownloadAudience { android, ios, desktop }

enum AppDownloadLaunchResult { opened, missingUrl, failed }

class AppDownloadPromotionService {
  static const String _lastShownKey = 'lpa_web_lastPromotionShownAt';
  static const String _lastDismissedKey = 'lpa_web_lastPromotionDismissedAt';
  static const String _downloadClickedKey =
      'lpa_web_promotionDownloadClickedAt';

  static bool _shownThisSession = false;
  static bool _downloadClickedThisSession = false;

  AppDownloadAudience get audience {
    if (!kIsWeb) return AppDownloadAudience.desktop;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AppDownloadAudience.android;
      case TargetPlatform.iOS:
        return AppDownloadAudience.ios;
      default:
        return AppDownloadAudience.desktop;
    }
  }

  Future<bool> canShowPromotion() async {
    if (!kIsWeb || _shownThisSession || _downloadClickedThisSession) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      if (_isInsideCooldown(
        prefs.getString(_downloadClickedKey),
        now,
        AppPromotionConfig.downloadClickCooldown,
      )) {
        return false;
      }

      if (_isInsideCooldown(
        prefs.getString(_lastDismissedKey),
        now,
        AppPromotionConfig.dismissCooldown,
      )) {
        return false;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> recordShown() async {
    _shownThisSession = true;
    await _setTimestamp(_lastShownKey);
  }

  Future<void> recordDismissed() async {
    await _setTimestamp(_lastDismissedKey);
  }

  Future<void> recordDownloadClicked() async {
    _downloadClickedThisSession = true;
    await _setTimestamp(_downloadClickedKey);
  }

  Future<AppDownloadLaunchResult> openStore(AppDownloadStore store) async {
    final url = switch (store) {
      AppDownloadStore.appStore => AppStoreLinks.appStore,
      AppDownloadStore.playStore => AppStoreLinks.playStore,
    };

    if (url == null || url.trim().isEmpty) {
      return AppDownloadLaunchResult.missingUrl;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) return AppDownloadLaunchResult.failed;

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) {
        await recordDownloadClicked();
        return AppDownloadLaunchResult.opened;
      }
      return AppDownloadLaunchResult.failed;
    } catch (_) {
      return AppDownloadLaunchResult.failed;
    }
  }

  bool _isInsideCooldown(String? isoDate, DateTime now, Duration cooldown) {
    if (isoDate == null || isoDate.isEmpty) return false;
    final date = DateTime.tryParse(isoDate);
    if (date == null) return false;
    return now.difference(date) < cooldown;
  }

  Future<void> _setTimestamp(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (_) {
      // Browser storage can be unavailable in private modes. The site still works.
    }
  }
}
