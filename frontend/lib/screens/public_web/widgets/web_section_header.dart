import 'package:flutter/material.dart';

class WebSectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? body;
  final TextAlign textAlign;
  final double maxWidth;

  const WebSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.body,
    this.textAlign = TextAlign.center,
    this.maxWidth = 760,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: textAlign == TextAlign.center
          ? Alignment.center
          : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: textAlign == TextAlign.center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              textAlign: textAlign,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: textAlign,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.14,
                letterSpacing: 0,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 16),
              Text(
                body!,
                textAlign: textAlign,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.65,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
