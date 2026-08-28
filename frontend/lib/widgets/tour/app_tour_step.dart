import 'package:flutter/material.dart';

/// Position of the info card relative to the target element.
enum TourCardPosition {
  auto,
  top,
  bottom,
  left,
  right,
}

/// Represents a single step in a page-based tour.
class AppTourStep {
  /// GlobalKey of the UI widget to highlight (optional; if null, card is centered without spotlight).
  final GlobalKey? targetKey;

  /// Short headline title for this step.
  final String title;

  /// Short, friendly description explaining the feature.
  final String description;

  /// Optional padding around the target highlight spotlight.
  final EdgeInsets spotlightPadding;

  /// Border radius for the spotlight cutout.
  final BorderRadius borderRadius;

  /// Preferred card placement relative to the target.
  final TourCardPosition preferredPosition;

  /// Optional custom widget content to embed inside the card.
  final Widget? customContent;

  const AppTourStep({
    this.targetKey,
    required this.title,
    required this.description,
    this.spotlightPadding = const EdgeInsets.all(8.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(16.0)),
    this.preferredPosition = TourCardPosition.auto,
    this.customContent,
  });
}
