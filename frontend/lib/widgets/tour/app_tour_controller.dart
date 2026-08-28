import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTourController {
  static const String _prefix = 'tour_';
  static const String _suffix = '_completed';

  /// Generates the SharedPreferences key for a given page.
  static String getKey(String pageId) => '$_prefix${pageId.toLowerCase()}$_suffix';

  static final StreamController<String> _tourCompletionStreamController = StreamController<String>.broadcast();

  /// Stream of pageIds that have just completed their tour.
  static Stream<String> get onTourCompleted => _tourCompletionStreamController.stream;

  /// Check whether the tour for [pageId] has already been completed or skipped.
  /// Always returns true on Web since web tour display is disabled.
  static Future<bool> isTourCompleted(String pageId) async {
    if (kIsWeb) return true; // Disabled for Web as requested
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(getKey(pageId)) ?? false;
    } catch (e) {
      debugPrint('[AppTourController] Error reading tour state: $e');
      return false;
    }
  }

  /// Mark the tour for [pageId] as completed.
  static Future<void> markTourCompleted(String pageId) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(getKey(pageId), true);
      _tourCompletionStreamController.add(pageId);
    } catch (e) {
      debugPrint('[AppTourController] Error marking tour completed: $e');
    }
  }

  /// Reset completion state for a specific page tour.
  static Future<void> resetTour(String pageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(getKey(pageId));
    } catch (e) {
      debugPrint('[AppTourController] Error resetting tour for $pageId: $e');
    }
  }

  /// Reset completion states for all app tours.
  static Future<void> resetAllTours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix) && k.endsWith(_suffix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('[AppTourController] Error resetting all tours: $e');
    }
  }
}
