import 'package:flutter/material.dart';

import 'package:life_partner_again/core/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your mobile number to continue.",
          style: TextStyle(
            fontSize: 16,
            color:
                Theme.of(context).textTheme.bodyMedium?.color ??
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class LoginWebBanner extends StatelessWidget {
  const LoginWebBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_person_rounded,
            size: 150,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            "Secure Login",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Your privacy is our priority. Login safely to find your perfect match.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
