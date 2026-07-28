import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import '../widgets/partner_preference_controller.dart';

class MobilePartnerPreferenceScreen extends StatefulWidget {
  const MobilePartnerPreferenceScreen({super.key});

  @override
  State<MobilePartnerPreferenceScreen> createState() =>
      _MobilePartnerPreferenceScreenState();
}

class _MobilePartnerPreferenceScreenState
    extends State<MobilePartnerPreferenceScreen>
    with PartnerPreferenceControllerState {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopNavigation(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, animation) {
                              final offsetBegin = goingForward
                                  ? const Offset(0.1, 0)
                                  : const Offset(-0.1, 0);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: offsetBegin,
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              key: ValueKey(currentStep),
                              child: buildCurrentStep(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              OnboardingContinueButton(
                canProceed: isCurrentStepValid,
                isLoading: isLoading,
                isLastStep: false,
                label: currentStep == totalSteps - 1
                    ? 'Set Profile Images'
                    : null,
                onNext: next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        height: 48,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Visibility(
              visible: currentStep > 0,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: IconButton(
                onPressed: back,
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: currentStep > 0 ? 12 : 0,
                  right: 12,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (currentStep + 1) / totalSteps,
                    backgroundColor: AppColors.borderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
