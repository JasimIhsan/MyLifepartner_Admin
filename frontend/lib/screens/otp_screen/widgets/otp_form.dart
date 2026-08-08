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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: isWeb ? 56 : 48,
      height: isWeb ? 64 : 56,
      textStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color:
            Theme.of(context).textTheme.bodyLarge?.color ??
            (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorderColor
              : AppColors.borderColor.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 2,
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
              focusedPinTheme: focusedPinTheme,
              submittedPinTheme: submittedPinTheme,
              errorPinTheme: errorPinTheme,
              separatorBuilder: (index) => SizedBox(width: isWeb ? 10 : 8),
              forceErrorState: errorMessage != null,
              errorText: errorMessage,
              errorTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
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
            ),
          ),
          const SizedBox(height: 24),

          // Timer / Resend Text
          Center(
            child: Text.rich(
              TextSpan(
                text: "Didn't receive a code? ",
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      AppColors.textSecondary,
                ),
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
                          const SizedBox(width: 6),
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
                      alignment: PlaceholderAlignment.middle,
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
                          "Resend in 00.${timerValue.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            AppColors.textPrimary,
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
                  borderRadius: 14,
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