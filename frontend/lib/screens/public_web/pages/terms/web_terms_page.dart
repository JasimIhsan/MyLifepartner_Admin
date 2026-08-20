import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';

class WebTermsPage extends StatelessWidget {
  const WebTermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalContentSection(
      title: 'Terms & Conditions',
      body:
          'These terms summarize the expectations for using Life Partner Again respectfully, safely, and in line with the app\'s relationship-focused purpose.',
      blocks: [
        LegalContentBlock(
          title: 'Purpose of LPA',
          body:
              'Life Partner Again is intended for adults seeking genuine, long-term relationships and marriage-minded companionship. It is not designed for casual dating or misuse.',
        ),
        LegalContentBlock(
          title: 'Member responsibility',
          body:
              'Members are responsible for providing truthful profile information, communicating respectfully, and using safety tools when needed.',
        ),
        LegalContentBlock(
          title: 'Verification and moderation',
          body:
              'LPA may use verification, profile review, moderation, report, block, and suspension workflows to protect the quality of the community.',
        ),
        LegalContentBlock(
          title: 'Membership and subscriptions',
          body:
              'Subscriptions may renew automatically according to the selected plan unless cancelled through the relevant App Store, Google Play account, or account settings where supported.',
        ),
        LegalContentBlock(
          title: 'Safe conduct',
          body:
              'Members should communicate inside the app first, avoid sending money to people they have only met online, meet safely, and report suspicious behaviour.',
        ),
        LegalContentBlock(
          title: 'Changes',
          body:
              'LPA may update features, membership benefits, and legal terms as the platform evolves. Updated terms will apply according to the policy presented to members.',
        ),
      ],
    );
  }
}
