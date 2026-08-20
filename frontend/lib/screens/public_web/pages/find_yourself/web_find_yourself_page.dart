import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/pages/find_yourself/widgets/find_yourself_hero.dart';
import 'package:life_partner_again/screens/public_web/pages/find_yourself/widgets/self_awareness_features.dart';
import 'package:life_partner_again/screens/public_web/pages/find_yourself/widgets/guided_questions_section.dart';
import 'package:life_partner_again/screens/public_web/pages/find_yourself/widgets/golden_results_grid.dart';

class WebFindYourselfPage extends StatelessWidget {
  const WebFindYourselfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FindYourselfHero(),
        SelfAwarenessFeatures(),
        GuidedQuestionsSection(),
        GoldenResultsGrid(),
      ],
    );
  }
}
