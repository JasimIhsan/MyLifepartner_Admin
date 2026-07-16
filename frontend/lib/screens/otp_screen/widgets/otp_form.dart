import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:pinput/pinput.dart';

class OtpForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController pinController;
  final FocusNode focusNode;
  final bool isWeb;
  final bool isLoading;
  final bool isResending;
  final String email;
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
    required this.isResending,
    required this.email,
    required this.onResend,
    required this.onVerify,
    required this.timerValue,
    required this.isResendEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 26,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 3)),
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
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                textStyle: const TextStyle(
                  fontSize: 26,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                textStyle: const TextStyle(
                  fontSize: 26,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.error, width: 4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Timer / Resend Text
          Center(
            child: Text.rich(
              TextSpan(
                text: "Didn't receive a code? ",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                children: [
                  if (isResending)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Resending",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 6),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isResendEnabled)
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: onResend,
                        child: const Text(
                          "Resend",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                  else
                    TextSpan(
                      text:
                          "Resent in 00.${timerValue.toString().padLeft(2, '0')}",
                      style: const TextStyle(
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
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: pinController,
              builder: (context, value, child) {
                final isEnabled = !isLoading && value.text.isNotEmpty;
                return CustomButton(
                  onPressed: isEnabled
                      ? () {
                          focusNode.unfocus();
                          if (formKey.currentState!.validate()) {
                            onVerify(pinController.text);
                          }
                        }
                      : null,
                  isLoading: isLoading,
                  text: "Verify",
                  borderRadius: 12,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
