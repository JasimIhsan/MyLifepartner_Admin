import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/otp_controller.dart';
import '../widgets/otp_form.dart';
import '../widgets/otp_header.dart';

class MobileOtpScreen extends StatefulWidget {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  const MobileOtpScreen({
    super.key,
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });

  @override
  State<MobileOtpScreen> createState() => _MobileOtpScreenState();
}

class _MobileOtpScreenState extends State<MobileOtpScreen>
    with OtpControllerState {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final backgroundColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.65,
            child: Consumer<ImageAssetProvider>(
              builder: (context, provider, _) {
                final asset = provider.getFeaturedAsset('ONBOARDING_SCREEN');
                if (asset != null) {
                  return CachedNetworkImage(
                    imageUrl: asset.imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  );
                }
                return Image.asset(
                  'assets/images/landing_couple.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                );
              },
            ),
          ),

          // Seamless Gradient Fade to Background Color (no hard cutoff)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.72,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 0.80, 1.0],
                  colors: [
                    backgroundColor.withValues(alpha: 0.0),
                    backgroundColor.withValues(alpha: 0.3),
                    backgroundColor.withValues(alpha: 0.9),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          // Main Scrollable Content Area with Keyboard Support
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back Button
                            if (context.canPop())
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () => context.pop(),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 48),

                            const Spacer(),
                            const SizedBox(height: 16),

                            // OTP Header
                            OtpHeader(
                              email: widget.email,
                              isWeb: false,
                              isPasswordReset: widget.isPasswordReset,
                            ),
                            const SizedBox(height: 28),

                            // OTP Form
                            OtpForm(
                              formKey: formKey,
                              pinController: pinController,
                              focusNode: focusNode,
                              isWeb: false,
                              isLoading: isLoading,
                              isResending: isResending,
                              email: widget.email,
                              onResend: resendOtp,
                              onVerify: verifyOtp,
                              timerValue: remainingSeconds,
                              isResendEnabled: isResendEnabled,
                              errorMessage: errorMessage,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
