import 'package:flutter/material.dart';

class VerifiedIconWidget extends StatelessWidget {
  final bool isVerified;
  final bool isFoundingMember;
  final bool isPremium;
  final double size;
  final EdgeInsetsGeometry? padding;

  const VerifiedIconWidget({
    super.key,
    required this.isVerified,
    this.isFoundingMember = false,
    this.isPremium = false,
    this.size = 18.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium || isFoundingMember) {
      final widget = Image.asset(
        'assets/icons/verified_premium_icon.png',
        width: size,
        height: size,
      );
      return padding != null ? Padding(padding: padding!, child: widget) : widget;
    } else if (isVerified) {
      final widget = Image.asset(
        'assets/icons/verified_icon.png',
        width: size,
        height: size,
      );
      return padding != null ? Padding(padding: padding!, child: widget) : widget;
    }

    return const SizedBox.shrink();
  }
}
