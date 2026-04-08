import 'package:flutter/material.dart';

import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/shared/widgets/custom_bottom_sheet.dart';

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
          "Verify Your Number",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: _OtpMethodSelectionContent(
            onMethodSelected: (method) {
              Navigator.pop(context);
              onMethodSelected(method);
            },
          ),
        ),
      ),
    );
  }

  static void _showMobileOtpBottomSheet(
    BuildContext context,
    Function(String) onMethodSelected,
  ) {
    CustomBottomSheet.showContent(
      context: context,
      isScrollControlled: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 24),
            _OtpMethodSelectionContent(
              onMethodSelected: (method) {
                Navigator.pop(context);
                onMethodSelected(method);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpMethodSelectionContent extends StatefulWidget {
  final Function(String) onMethodSelected;

  const _OtpMethodSelectionContent({required this.onMethodSelected});

  @override
  State<_OtpMethodSelectionContent> createState() =>
      _OtpMethodSelectionContentState();
}

class _OtpMethodSelectionContentState
    extends State<_OtpMethodSelectionContent> {
  String? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Verify Your Number",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Select how you'd like to receive the code.",
          style: TextStyle(fontSize: 15, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),
        _buildOption(method: "SMS", icon: Icons.sms_outlined, label: "SMS"),
        const SizedBox(height: 16),
        _buildOption(
          method: "WhatsApp",
          icon: Icons
              .message_outlined, // Using message icon as generic whatsapp-like
          label: "WhatsApp",
          isWhatsApp: true,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedMethod != null
                ? () => widget.onMethodSelected(_selectedMethod!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.black.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              "Continue",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOption({
    required String method,
    required IconData icon,
    required String label,
    bool isWhatsApp = false,
  }) {
    final isSelected = _selectedMethod == method;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isWhatsApp
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isWhatsApp ? Colors.black : Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ), // Or checkmark style from screenshot?
            // Screenshot shows a red checkmark for WhatsApp. Let's stick to standard verified check for selected.
            // Actually screenshot has a reddish checkmark circle.
            // Let's use the brown color for check? The screenshot shows a reddish/brown check for WhatsApp.
            // Selection border is Blue in screenshot for SMS.
            // Wait, the screenshot shows:
            // SMS selected -> Blue border, no icon? (Or maybe just blue border)
            // WhatsApp unselected -> Normal border, check icon?
            // The screenshot shows "WhatsApp" with a red checkmark circle on the right.
            // And "SMS" has a blue border.
            // It seems "SMS" is selected in one, and "WhatsApp" might be the choice?
            // Let's implement standard selection logic: Selected gets border + check icon.
          ],
        ),
      ),
    );
  }
}
