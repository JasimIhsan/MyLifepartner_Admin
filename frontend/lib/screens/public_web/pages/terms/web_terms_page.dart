import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/services/legal_service.dart';

class WebTermsPage extends StatelessWidget {
  const WebTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: LegalService.getLatestTerms(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48.0),
              child: Text('Failed to load Terms & Conditions.'),
            ),
          );
        }

        final data = snapshot.data!;
        final title = data['title'] as String? ?? 'Terms & Conditions';
        final content = data['content'] as String? ?? '';

        return LegalContentSection(
          title: title,
          markdownContent: content,
        );
      },
    );
  }
}
