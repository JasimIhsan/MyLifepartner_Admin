import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/widgets/faq_accordion.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class WebFaqPage extends StatelessWidget {
  const WebFaqPage({super.key});

  static const _items = [
    FaqItem(
      question: 'What is Life Partner Again?',
      answer:
          'Life Partner Again is a Canadian premium relationship platform created for mature individuals seeking genuine, long-term relationships and marriage.',
    ),
    FaqItem(
      question: 'Is my information private?',
      answer:
          'Your personal information is protected using platform security measures. LPA does not sell personal data to third parties.',
    ),
    FaqItem(
      question: 'How does verification work?',
      answer:
          'Verification helps build trust through steps such as email OTP, selfie verification, and profile review where applicable.',
    ),
    FaqItem(
      question: 'Can I report or block someone?',
      answer:
          'Yes. If someone behaves inappropriately, you can block and report them from inside the app for review.',
    ),
    FaqItem(
      question: 'How do I get started?',
      answer:
          'Download the app, create your profile, complete verification, reflect on your preferences, and begin discovering compatible people.',
    ),
    FaqItem(
      question: 'Which devices does LPA support?',
      answer:
          'The main LPA experience is available through the Android and iOS apps. This website helps people learn about LPA and download the app.',
    ),
    FaqItem(
      question: 'How do notifications work?',
      answer:
          'The app can notify you about relevant activity such as messages and connection updates when notification permissions are enabled.',
    ),
    FaqItem(
      question: 'What should I do if I forget my password?',
      answer:
          'Use the Forgot Password option on the login screen. LPA sends an OTP to your registered email address so you can continue securely.',
    ),
    FaqItem(
      question: 'How do I contact support?',
      answer:
          'Use the Help & Support area in the app or email the support team. Contact details are also listed in the website footer.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.65,
          color: theme.brightness == Brightness.dark
              ? theme.scaffoldBackgroundColor
              : const Color(0xFFFFFBFB),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: WebSectionHeader(
                  eyebrow: 'FAQ',
                  title: 'Common questions before you download.',
                  body:
                      'A quick guide to privacy, safety, membership, devices, notifications, password reset, and support.',
                ),
              ),
            ],
          ),
        ),
        const PublicWebSection(
          topPadding: 56,
          maxWidth: 900,
          child: FaqAccordion(items: _items),
        ),
      ],
    );
  }
}
