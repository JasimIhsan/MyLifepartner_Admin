import 'package:flutter/material.dart';

import 'widgets/founding_member_banner.dart';
import 'widgets/membership_comparison_table.dart';
import 'widgets/membership_hero.dart';
import 'widgets/membership_pricing_cards.dart';

class WebMembershipPage extends StatelessWidget {
  const WebMembershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        MembershipHero(),
        SizedBox(height: 64),
        FoundingMemberBanner(),
        SizedBox(height: 64),
        MembershipPricingCards(),
        SizedBox(height: 80),
        MembershipComparisonTable(),
        SizedBox(height: 80),
      ],
    );
  }
}
