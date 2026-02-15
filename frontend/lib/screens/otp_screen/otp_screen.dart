import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/screens/otp_screen/widgets/otp_header.dart';
import 'package:mylifepartner/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/auth_layout.dart';
import '../home_screen/home_screen.dart';
import 'widgets/otp_form.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String verificationMethod;
  final String code;
  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.verificationMethod,
    required this.code,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Timer? _timer;
  int _remainingSeconds = 30;
  bool get _isResendEnabled => _remainingSeconds == 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

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

      if (response.data["success"]) {
        final sharedPrefs = await SharedPreferences.getInstance();
        sharedPrefs.setBool("isLoggedIn", true);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            ModalRoute.withName('/'),
          );
        }
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
    if (!_isResendEnabled) return;

    try {
      await ApiService.client.post(
        "/user/auth/send-otp",
        data: {
          "mobileNumber": widget.phoneNumber,
          "sendOption": widget.verificationMethod.toLowerCase(),
        },
      );

      _startTimer();

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
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = MediaQuery.of(context).size.width > 900;
          return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OtpHeader(
                verificationMethod: widget.verificationMethod,
                phoneNumber: widget.phoneNumber,
                isWeb: isWeb,
                code: widget.code,
              ),
              const SizedBox(height: 32),
              OtpForm(
                formKey: formKey,
                pinController: pinController,
                focusNode: focusNode,
                isWeb: isWeb,
                isLoading: _isLoading,
                phoneNumber: widget.phoneNumber,
                onResend: _resendOtp,
                onVerify: _verifyOtp,
                timerValue: _remainingSeconds,
                isResendEnabled: _isResendEnabled,
              ),
            ],
          );
        },
      ),
    );
  }
}
