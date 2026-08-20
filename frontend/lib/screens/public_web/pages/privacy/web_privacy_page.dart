import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';

class WebPrivacyPage extends StatelessWidget {
  const WebPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalContentSection(
      title: 'Privacy Policy',
      body:
          'This page summarizes how LPA approaches privacy, safety, and member control across the website and mobile app experience.',
      blocks: [
        LegalContentBlock(
          title: 'Information and privacy settings',
          body:
              'LPA uses account and profile information to provide matching, discovery, messaging, verification, and account features. Members can manage visibility and privacy controls in the app where supported.',
        ),
        LegalContentBlock(
          title: 'Verification and trust',
          body:
              'Verification signals such as email OTP, selfie verification, and profile review help build trust and reduce misuse of the community.',
        ),
        LegalContentBlock(
          title: 'Data protection',
          body:
              'The app is designed to handle account details securely and to avoid selling personal information to third parties.',
        ),
        LegalContentBlock(
          title: 'Reports, moderation, and safety',
          body:
              'Reports and blocks may be reviewed to maintain a respectful community and address suspicious or inappropriate behaviour.',
        ),
        LegalContentBlock(
          title: 'Account deletion',
          body:
              'Members may permanently delete their account from the app. Deleted profile data is removed according to the final privacy policy and operational requirements.',
        ),
        LegalContentBlock(
          title: 'Contact',
          body:
              'For privacy or support questions, use the support contact listed in the footer or the Help & Support section in the app.',
        ),
      ],
    );
  }
}
