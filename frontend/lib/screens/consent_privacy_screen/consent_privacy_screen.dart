import 'package:flutter/material.dart';
import 'package:life_partner_again/core/responsive/adaptive_screen.dart';

import 'mobile/mobile_consent_screen.dart';
import 'web/web_consent_screen.dart';

class ConsentPrivacyScreen extends StatelessWidget {
  final String? email;
  final String? password;
  final String? provider;
  final String? googleIdToken;
  final String? appleIdentityToken;
  final String? appleAuthorizationCode;
  final String? appleEmail;
  final String? appleFirstName;
  final String? appleLastName;
  final String? firstName;
  final String? lastName;

  const ConsentPrivacyScreen({
    super.key,
    this.email,
    this.password,
    this.provider,
    this.googleIdToken,
    this.appleIdentityToken,
    this.appleAuthorizationCode,
    this.appleEmail,
    this.appleFirstName,
    this.appleLastName,
    this.firstName,
    this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileConsentScreen(),
      web: WebConsentScreen(),
    );
  }
}
