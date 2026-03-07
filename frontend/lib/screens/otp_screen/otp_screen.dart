import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/screens/login_screen/widgets/otp_method_selector.dart';
import 'package:mylifepartner/screens/otp_screen/widgets/otp_header.dart';
import 'package:mylifepartner/screens/profile_completion/profile_completion_screen.dart';
import 'package:mylifepartner/services/auth_repository.dart';
import 'package:mylifepartner/utils/dio_error_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/widgets/auth_layout.dart';
import '../home_screen/home_screen.dart';
import '../partner_preference/partner_preference_screen.dart';
import '../profile_image_upload/profile_image_upload_screen.dart';
import '../questionaire_screen/questionaire_screen.dart';
import '../selfie_verification/selfie_verification_screen.dart';
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
  final AuthRepository _authRepository = AuthRepository();
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
      final response = await _authRepository.verifyOtp(
        mobileNumber: widget.phoneNumber,
        otp: pin,
      );

      debugPrint("Login Response: ${response.message}");

      if (response.success == true) {
        final sharedPrefs = await SharedPreferences.getInstance();
        sharedPrefs.setBool("isLoggedIn", true);

        final user = response.user;
        if (user != null) {
          sharedPrefs.setInt("userId", user.id);
          sharedPrefs.setString("profileStatus", user.profileStatus);
          sharedPrefs.setBool(
            "hasCompletedBasicDetails",
            user.hasCompletedBasicDetails,
          );
          sharedPrefs.setBool(
            "hasCompletedImageUpload",
            user.hasCompletedImageUpload,
          );
          sharedPrefs.setBool(
            "hasCompletedPartnerPreference",
            user.hasCompletedPartnerPreference,
          );
          if (user.name != null) {
            sharedPrefs.setString("name", user.name!);
          } else {
            sharedPrefs.remove("name");
          }
          sharedPrefs.setString("selfieStatus", user.selfieStatus ?? "NONE");

          if (!user.hasCompletedBasicDetails) {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileCompletionScreen(),
                ),
                ModalRoute.withName('/'),
              );
            }
          } else if (!user.hasCompletedPartnerPreference) {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PartnerPreferenceScreen(),
                ),
                ModalRoute.withName('/'),
              );
            }
          } else if (user.profileStatus == "INCOMPLETE") {
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuestionaireScreen(),
                ),
                ModalRoute.withName('/'),
              );
            }
          } else {
            if (mounted) {
              if (user.hasCompletedImageUpload == false) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileImageUploadScreen(),
                  ),
                  ModalRoute.withName('/'),
                );
              } else if (user.selfieStatus == null ||
                  user.selfieStatus == "NONE") {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelfieVerificationScreen(),
                  ),
                  ModalRoute.withName('/'),
                );
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  ModalRoute.withName('/'),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      String errorMessage = "Invalid OTP. Please try again.";
      if (e is DioException) {
        errorMessage = getDioErrorMessage(e, fallback: errorMessage);
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

    final bool isWeb = MediaQuery.of(context).size.width > 900;

    OtpMethodSelector.show(
      context,
      isWeb: isWeb,
      onMethodSelected: (method) async {
        try {
          await _authRepository.resendOtp(
            mobileNumber: widget.phoneNumber,
            sendOption: method.toLowerCase(),
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
          String errorMessage = "Failed to resend OTP";
          if (e is DioException) {
            errorMessage = getDioErrorMessage(e, fallback: errorMessage);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      },
    );
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
