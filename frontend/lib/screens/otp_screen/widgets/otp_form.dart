import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/shared/widgets/custom_button.dart';
import 'package:pinput/pinput.dart';

class OtpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController pinController;
  final FocusNode focusNode;
  final bool isWeb;
  final bool isLoading;
  final String phoneNumber;
  final VoidCallback onResend;
  final Function(String) onVerify;
  final int timerValue;
  final bool isResendEnabled;

  const OtpForm({
    super.key,
    required this.formKey,
    required this.pinController,
    required this.focusNode,
    required this.isWeb,
    required this.isLoading,
    required this.phoneNumber,
    required this.onResend,
    required this.onVerify,
    required this.timerValue,
    required this.isResendEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Pinput(
              length: 6,
              controller: pinController,
              focusNode: focusNode,
              defaultPinTheme: defaultPinTheme,
              separatorBuilder: (index) => const SizedBox(width: 8),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Please enter 6-digit OTP';
                }
                return null;
              },
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              onCompleted: onVerify,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: Colors.black),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  color: Colors.black.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.black),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyBorderWith(
                border: Border.all(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Timer / Resend Text
          Center(
            child: Text.rich(
              TextSpan(
                text: "Didn't receive a code? ",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                children: [
                  if (isResendEnabled)
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: onResend,
                        child: Text(
                          "Resend",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                  else
                    TextSpan(
                      text:
                          "Resent in 00.${timerValue.toString().padLeft(2, '0')}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: CustomButton(
              onPressed: _isVerifyButtonEnabled()
                  ? () {
                      focusNode.unfocus();
                      if (formKey.currentState!.validate()) {
                        onVerify(pinController.text);
                      }
                    }
                  : null,
              isLoading: isLoading,
              text: "Verify",
              backgroundColor: Colors.black,
              borderRadius: 12,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isVerifyButtonEnabled() {
    return !isLoading;
  }
}
