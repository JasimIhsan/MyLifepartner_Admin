import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/services/api_service.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';
import 'package:phone_form_field/phone_form_field.dart';

import '../../core/app_colors.dart';
import '../../shared/widgets/auth_layout.dart';
import '../otp_screen/otp_screen.dart';
import 'widgets/otp_method_selector.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final PhoneController _phoneController;
  PhoneNumber _phoneNumber = const PhoneNumber(isoCode: IsoCode.US, nsn: "");
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = PhoneController(initialValue: _phoneNumber);
    _detectCountry();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _detectCountry() async {
    try {
      final response = await ApiService.client.get("/user/auth/detect-country");
      final data = response.data['data'];
      if (data != null && data['countryCode'] != null) {
        final String code = data['countryCode'];
        final detectedIsoCode = IsoCode.values.firstWhere(
          (e) => e.name.toUpperCase() == code.toUpperCase(),
          orElse: () => IsoCode.IN,
        );

        if (mounted) {
          setState(() {
            _phoneNumber = PhoneNumber(isoCode: detectedIsoCode, nsn: "");
            _phoneController.value = _phoneNumber;
          });
        }
      }
    } catch (e) {
      debugPrint("Country detection failed: $e");
    }
  }

  Future<bool> _sendOtp(String method) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.client.post(
        "/user/auth/send-otp",
        data: {
          "mobileNumber": "+${_phoneNumber.countryCode}${_phoneNumber.nsn}",
          "sendOption": method.toLowerCase(),
        },
      );

      debugPrint("OTP Response: ${response.data}");
      return true;
    } catch (e) {
      debugPrint("Send OTP Error: $e");
      String errorMessage = "Failed to send OTP. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Check screen width for responsive text/style, matching AuthLayout breakpoint logic partially
          // AuthLayout uses 900 breakpoint for split screen.
          final bool isWeb = MediaQuery.of(context).size.width > 900;
          return _buildFormContent(isWeb);
        },
      ),
    );
  }

  Widget _buildFormContent(bool isWeb) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important for the bottom sheet layout
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Continue with Phone",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          PhoneFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                vertical: isWeb ? 16 : 14,
                horizontal: isWeb ? 16 : 10,
              ),
              hintText: "000 000 0000",
              hintStyle: const TextStyle(color: Colors.grey),
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFA67C68),
                ), // Brown focus
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
            validator: PhoneValidator.compose([
              PhoneValidator.required(
                context,
                errorText: "Please enter your mobile number",
              ),
              PhoneValidator.validMobile(
                context,
                errorText: "Please enter a valid mobile number",
              ),
            ]),
            countrySelectorNavigator: isWeb
                ? const CountrySelectorNavigator.dialog()
                : const CountrySelectorNavigator.draggableBottomSheet(),
            onChanged: (value) => _phoneNumber = value,
            isCountrySelectionEnabled: true,
            isCountryButtonPersistent: true,
            countryButtonStyle: const CountryButtonStyle(
              showIsoCode: false,
              showFlag: true,
              flagSize: 20,
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        OtpMethodSelector.show(
                          context,
                          isWeb: isWeb,
                          onMethodSelected: _navigateToOtp,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA67C68),
                disabledBackgroundColor: const Color(
                  0xFFA67C68,
                ).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Continue",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),
          _buildFooterText(),
        ],
      ),
    );
  }

  Widget _buildFooterText() {
    return Text.rich(
      TextSpan(
        text: "By continue, you agree to our ",
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
        children: [
          TextSpan(
            text: "Terms of Service",
            style: GoogleFonts.poppins(
              decoration: TextDecoration.underline,
              color: Colors.grey[400],
            ),
          ),
          const TextSpan(text: " and\n"),
          TextSpan(
            text: "Privacy Policy",
            style: GoogleFonts.poppins(
              decoration: TextDecoration.underline,
              color: Colors.grey[400],
            ),
          ),
          const TextSpan(text: "."),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  void _navigateToOtp(String method) async {
    final bool success = await _sendOtp(method);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpPage(
            code: "+${_phoneNumber.countryCode}",
            phoneNumber: "+${_phoneNumber.countryCode}${_phoneNumber.nsn}",
            verificationMethod: method,
          ),
        ),
      );
    }
  }
}
