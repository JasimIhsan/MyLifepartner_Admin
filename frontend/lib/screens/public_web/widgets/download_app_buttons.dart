import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/widgets/app_store_button.dart';
import 'package:life_partner_again/screens/public_web/widgets/play_store_button.dart';

enum DownloadButtonsMode { both, appStoreOnly, playStoreOnly }

class DownloadAppButtons extends StatelessWidget {
  final DownloadButtonsMode mode;
  final bool compact;
  final WrapAlignment alignment;

  const DownloadAppButtons({
    super.key,
    this.mode = DownloadButtonsMode.both,
    this.compact = false,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: alignment,
      children: [
        if (mode != DownloadButtonsMode.playStoreOnly)
          AppStoreButton(compact: compact),
        if (mode != DownloadButtonsMode.appStoreOnly)
          PlayStoreButton(compact: compact),
      ],
    );
  }
}
