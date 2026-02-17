import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:phone_form_field/phone_form_field.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final PhoneController phoneController;
  final bool isWeb;
  final bool isLoading;
  final Function(PhoneNumber) onPhoneChanged;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.isWeb,
    required this.isLoading,
    required this.onPhoneChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: isWeb
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (isWeb) ...[
            Text(
              "Welcome Back",
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Enter your mobile number to continue.",
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),
          ],
          PhoneFormField(
            controller: phoneController,
            validator: PhoneValidator.compose([
              PhoneValidator.required(
                context,
                errorText: 'Please enter your mobile number',
              ),
              PhoneValidator.validMobile(
                context,
                errorText: 'Please enter a valid mobile number',
              ),
            ]),
            countrySelectorNavigator: isWeb
                ? const CountrySelectorNavigator.dialog()
                : const CountrySelectorNavigator.draggableBottomSheet(),
            onChanged: onPhoneChanged,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        onSubmit();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Send OTP",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  "Sign Up",
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
