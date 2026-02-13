import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpMethodSelector {
  static void show(
    BuildContext context, {
    required bool isWeb,
    required Function(String) onMethodSelected,
  }) {
    if (isWeb) {
      _showWebOtpDialog(context, onMethodSelected);
    } else {
      _showMobileOtpBottomSheet(context, onMethodSelected);
    }
  }

  static void _showWebOtpDialog(
    BuildContext context,
    Function(String) onMethodSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Verify your number",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose how you'd like to receive the 6-digit verification code.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            OtpMethodOption(
              icon: Icons.chat_bubble_outline_rounded,
              title: "WhatsApp",
              subtitle: "Send OTP via WhatsApp",
              onTap: () => onMethodSelected("WhatsApp"),
            ),
            const SizedBox(height: 12),
            OtpMethodOption(
              icon: Icons.sms_outlined,
              title: "SMS",
              subtitle: "Send OTP via SMS",
              onTap: () => onMethodSelected("SMS"),
            ),
          ],
        ),
      ),
    );
  }

  static void _showMobileOtpBottomSheet(
    BuildContext context,
    Function(String) onMethodSelected,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Verify your number",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose how you'd like to receive the code",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              OtpMethodOption(
                icon: Icons.chat_bubble_outline_rounded,
                title: "WhatsApp",
                subtitle: "Get code on WhatsApp",
                onTap: () => onMethodSelected("WhatsApp"),
              ),
              const SizedBox(height: 16),
              OtpMethodOption(
                icon: Icons.sms_outlined,
                title: "SMS",
                subtitle: "Get code via SMS",
                onTap: () => onMethodSelected("SMS"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OtpMethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const OtpMethodOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 28),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
