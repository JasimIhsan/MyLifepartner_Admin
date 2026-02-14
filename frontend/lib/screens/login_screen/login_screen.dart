import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/services/api_service.dart';
import 'package:phone_form_field/phone_form_field.dart';

import '../../core/app_colors.dart';
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
      if (e is DioException && e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth > 900;
          final size = MediaQuery.of(context).size;

          if (isWeb) {
            return _buildWebLayout(size);
          }
          return _buildMobileLayout(size);
        },
      ),
    );
  }

  Widget _buildWebLayout(Size size) {
    return Row(
      children: [
        // Left Side - Image
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/icons/background.png', fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Optional: Logo or Text on the image side
                Positioned(
                  top: 40,
                  left: 40,
                  child: FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Life Partner Again",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side - Form
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 60.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(20),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'assets/icons/app_logo.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Text(
                              "Welcome Back",
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "A trusted platform for emotionally\nmature relationships.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Phone Input Section
                          Text(
                            "Continue with Phone",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PhoneFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, // Slightly taller for web
                                horizontal: 16,
                              ),
                              hintText: "000 000 0000",
                              hintStyle: const TextStyle(color: Colors.grey),
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // Smoother corners
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.error,
                                ),
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
                            countrySelectorNavigator:
                                const CountrySelectorNavigator.dialog(), // Use dialog for web
                            onChanged: (value) => _phoneNumber = value,
                            isCountrySelectionEnabled: true,
                            isCountryButtonPersistent: true,
                            countryButtonStyle: const CountryButtonStyle(
                              showIsoCode: false,
                              showFlag: true,
                              flagSize: 20,
                            ),
                          ),

                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56, // Taller button for web
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        OtpMethodSelector.show(
                                          context,
                                          isWeb:
                                              true, // Use web optimized selector
                                          onMethodSelected: _navigateToOtp,
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA67C68),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
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

                          const SizedBox(height: 32),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: Text.rich(
                                TextSpan(
                                  text: "By continue, you agree to our ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Size size) {
    // Calculate heights
    final double topHeight = size.height * 0.45;

    return SingleChildScrollView(
      child: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            // Background Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/icons/background.png',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.background.withValues(alpha: 0),
                            AppColors.background,
                          ],
                          stops: [0.55, 0.9],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Panel Content
            Positioned(
              top: topHeight - 40, // Overlap slightly or start just below?
              // Actually, looking at the design, the logo overlaps the line.
              // Let's place the bottom container starting at topHeight.
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.background,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 200),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        const SizedBox(height: 60), // Space for Logo
                        Text(
                          "Life Partner Again",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "A trusted platform for emotionally\nmature relationships.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Phone Input Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Continue with Phone",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PhoneFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 10,
                            ),
                            hintText: "000 000 0000",
                            hintStyle: const TextStyle(color: Colors.grey),
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          validator: PhoneValidator.compose([
                            PhoneValidator.required(context),
                            PhoneValidator.validMobile(context),
                          ]),
                          countrySelectorNavigator:
                              const CountrySelectorNavigator.draggableBottomSheet(),
                          onChanged: (value) => _phoneNumber = value,
                          isCountrySelectionEnabled: true,
                          isCountryButtonPersistent: true,
                          countryButtonStyle: const CountryButtonStyle(
                            // showDialCode: false,
                            showIsoCode: false,
                            showFlag: true,
                            flagSize: 20,
                          ),
                        ),

                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      // Default to SMS or show selector? The design just says "Continue".
                                      // I'll assume we show selector or just send.
                                      // Existing code used a selector. I'll trigger the selector.
                                      OtpMethodSelector.show(
                                        context,
                                        isWeb: false,
                                        onMethodSelected: _navigateToOtp,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFA67C68,
                              ), // Terracotta/Brown
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    "Continue",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Text.rich(
                            TextSpan(
                              text: "By continue, you agree to our ",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Logo overlapped
            Positioned(
              top: topHeight - 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black, // Placeholder for logo background
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: AssetImage('assets/icons/app_logo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOtp(String method) async {
    Navigator.pop(context); // Close sheet/dialog
    final bool success = await _sendOtp(method);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpPage(
            phoneNumber: "+${_phoneNumber.countryCode}${_phoneNumber.nsn}",
            verificationMethod: method,
          ),
        ),
      );
    }
  }
}
