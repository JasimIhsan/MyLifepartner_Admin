import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/services/api_service.dart';
import 'package:phone_form_field/phone_form_field.dart';

import '../../core/app_colors.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';
import 'widgets/otp_method_selector.dart';
import '../otp_screen/otp_screen.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth > 900;
            final size = MediaQuery.of(context).size;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 80.0 : 24.0,
                        vertical: 24.0,
                      ),
                      child: isWeb
                          ? _buildWebLayout(size)
                          : _buildMobileLayout(size),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebLayout(Size size) {
    return Row(
      children: [
        const Expanded(flex: 1, child: LoginWebBanner()),
        const SizedBox(width: 80),
        Expanded(
          flex: 1,
          child: LoginForm(
            formKey: _formKey,
            phoneController: _phoneController,
            isWeb: true,
            isLoading: _isLoading,
            onPhoneChanged: (value) {
              _phoneNumber = value;
            },
            onSubmit: () {
              OtpMethodSelector.show(
                context,
                isWeb: true,
                onMethodSelected: _navigateToOtp,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoginHeader(),
        const SizedBox(height: 48),
        LoginForm(
          formKey: _formKey,
          phoneController: _phoneController,
          isWeb: false,
          isLoading: _isLoading,
          onPhoneChanged: (value) {
            _phoneNumber = value;
          },
          onSubmit: () {
            OtpMethodSelector.show(
              context,
              isWeb: false,
              onMethodSelected: _navigateToOtp,
            );
          },
        ),
      ],
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
