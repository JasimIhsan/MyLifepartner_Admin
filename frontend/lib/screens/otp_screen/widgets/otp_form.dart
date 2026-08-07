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

  final String? errorMessage;

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
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: TextStyle(
        fontSize: 26,
        color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 3),
        ),
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
              forceErrorState: errorMessage != null,
              errorText: errorMessage,
              errorTextStyle: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.error,
              ),
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Please enter 6-digit OTP';
                }
                return null;
              },
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              onCompleted: onVerify,
              focusedPinTheme: defaultPinTheme.copyWith(
                textStyle: TextStyle(
                  fontSize: 26,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                  ),
                ),
              ),
              submittedPinTheme: defaultPinTheme.copyWith(
                textStyle: TextStyle(
                  fontSize: 26,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).primaryColor, width: 4),
                  ),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                textStyle: TextStyle(
                  fontSize: 26,
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).colorScheme.error, width: 4),
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
                style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary),
                children: [
                  if (isResending)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Resending",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          SizedBox(width: 6),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
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
                        child: Text(
                          "Resend",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    )
                  else
                    TextSpan(
                      text:
                          "Resent in 00.${timerValue.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary,
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
                final isEnabled =
                    !isLoading && !isResending && value.text.length == 6;
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