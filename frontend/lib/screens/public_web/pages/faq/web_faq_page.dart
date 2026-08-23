import 'package:flutter/material.dart';
import 'package:life_partner_again/screens/public_web/sections/public_web_shared_sections.dart';
import 'package:life_partner_again/screens/public_web/widgets/faq_accordion.dart';
import 'package:life_partner_again/screens/public_web/widgets/web_section_header.dart';

class WebFaqPage extends StatelessWidget {
  final String? initialExpandedId;

  const WebFaqPage({super.key, this.initialExpandedId});

  static const _items = [
    FaqItem(
      id: 'what-is-lpa',
      question: 'What is Life Partner Again?',
      answer:
          'Life Partner Again is a Canadian premium relationship platform created for mature individuals seeking genuine, long-term relationships and marriage.',
    ),
    FaqItem(
      id: 'privacy',
      question: 'Is my information private?',
      answer:
          'Your personal information is protected using platform security measures. LPA does not sell personal data to third parties.',
    ),
    FaqItem(
      id: 'verification',
      question: 'How does verification work?',
      answer:
          'Verification helps build trust through steps such as email OTP, selfie verification, and profile review where applicable.',
    ),
    FaqItem(
      id: 'safety',
      question: 'Can I report or block someone?',
      answer:
          'Yes. If someone behaves inappropriately, you can block and report them from inside the app for review.',
    ),
    FaqItem(
      id: 'getting-started',
      question: 'How do I get started?',
      answer:
          'Download the app, create your profile, complete verification, reflect on your preferences, and begin discovering compatible people.',
    ),
    FaqItem(
      id: 'devices',
      question: 'Which devices does LPA support?',
      answer:
          'The main LPA experience is available through the Android and iOS apps. This website helps people learn about LPA and download the app.',
    ),
    FaqItem(
      id: 'notifications',
      question: 'How do notifications work?',
      answer:
          'The app can notify you about relevant activity such as messages and connection updates when notification permissions are enabled.',
    ),
    FaqItem(
      id: 'password-reset',
      question: 'What should I do if I forget my password?',
      answer:
          'Use the Forgot Password option on the login screen. LPA sends an OTP to your registered email address so you can continue securely.',
    ),
    FaqItem(
      id: 'support',
      question: 'How do I contact support?',
      answer:
          'Use the Help & Support area in the app or email the support team. Contact details are also listed in the website footer.',
    ),
    FaqItem(
      id: 'account-deletion',
      question: 'How do I delete my app account and data?',
      answer:
          '''If you wish to permanently delete your account and personal information from Life Partner Again, please follow these steps:

Send an email to support@lifepartneragain.com.

You must send this email from the exact email address you used to register your account.

Use the subject line: "Account Deletion Request".

In the body of the email, simply state that you would like your account deleted.

What happens to your data:

Data Deleted: Upon verifying your request, we will permanently delete your user profile, uploaded photos, chat history, match preferences, and login credentials from our active servers within 30 days.

Data Retained: If you have purchased a premium subscription, strictly necessary transaction and billing records (processed via RevenueCat) will be securely retained only as long as required for tax, legal, and anti-fraud compliance.

Irreversible Action: Please be aware that once the deletion process is complete, your profile and connections cannot be recovered.''',
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
        PublicWebSection(
          topPadding: 56,
          maxWidth: 900,
          child: FaqAccordion(
            items: _items,
            initialExpandedId: initialExpandedId,
          ),
        ),
      ],
    );
  }
}
