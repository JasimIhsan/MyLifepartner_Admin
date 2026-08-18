import 'package:flutter/material.dart';
import 'package:life_partner_again/widgets/custom_popover_tooltip.dart';

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
      final widget = CustomPopoverTooltip(
        title: 'Premium Member',
        description:
            'This user is a verified premium member who can respond quickly to messages.',
        child: Image.asset(
          'assets/icons/verified_premium_icon.png',
          width: size,
          height: size,
        ),
      );
      return padding != null ? Padding(padding: padding!, child: widget) : widget;
    } else if (isVerified) {
      final widget = CustomPopoverTooltip(
        title: 'Verified Profile',
        description:
            'This profile has been verified and authenticated by our moderation team.',
        child: Image.asset(
          'assets/icons/verified_icon.png',
          width: size,
          height: size,
        ),
      );
      return padding != null ? Padding(padding: padding!, child: widget) : widget;
    }

    return const SizedBox.shrink();
  }
}
