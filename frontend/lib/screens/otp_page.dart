import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/services/api_service.dart';

import '../widgets/otp/otp_form.dart';
import '../widgets/otp/otp_header.dart';
import 'home_page.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationMethod;
  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.verificationMethod,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _verifyOtp(String pin) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await ApiService.client.post(
        "/user/auth/login",
        data: {"mobileNumber": widget.phoneNumber, "otp": pin},
      );

      debugPrint("Login Response: ${response.data}");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      String errorMessage = "Invalid OTP. Please try again.";
      if (e is DioException && e.response != null) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    try {
      await ApiService.client.post(
        "/user/auth/send-otp",
        data: {
          "mobileNumber": widget.phoneNumber,
          "sendOption": widget.verificationMethod.toLowerCase(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP resent successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Resend OTP Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to resend OTP"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
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
        Expanded(
          flex: 1,
          child: OtpWebBanner(verificationMethod: widget.verificationMethod),
        ),
        const SizedBox(width: 80),
        Expanded(
          flex: 1,
          child: OtpForm(
            formKey: formKey,
            pinController: pinController,
            focusNode: focusNode,
            isWeb: true,
            isLoading: _isLoading,
            phoneNumber: widget.phoneNumber,
            onResend: _resendOtp,
            onVerify: _verifyOtp,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OtpHeader(
          verificationMethod: widget.verificationMethod,
          phoneNumber: widget.phoneNumber,
        ),
        const SizedBox(height: 48),
        OtpForm(
          formKey: formKey,
          pinController: pinController,
          focusNode: focusNode,
          isWeb: false,
          isLoading: _isLoading,
          phoneNumber: widget.phoneNumber,
          onResend: _resendOtp,
          onVerify: _verifyOtp,
        ),
      ],
    );
  }
}
