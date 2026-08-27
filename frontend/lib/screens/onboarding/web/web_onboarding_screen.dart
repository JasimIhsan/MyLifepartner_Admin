import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_controller.dart';

class WebOnboardingScreen extends StatefulWidget {
  const WebOnboardingScreen({super.key});

  @override
  State<WebOnboardingScreen> createState() => _WebOnboardingScreenState();
}

class _WebOnboardingScreenState extends State<WebOnboardingScreen>
    with OnboardingControllerState {
  // ─── Breakpoints ────────────────────────────────────────────────────────────
  // < 1024 → tablet portrait (single column, no left panel)
  // 1024–1279 → small desktop / landscape tablet (two-column, narrower left)
  // ≥ 1280 → full desktop (two-column, wider left)

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).canvasColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width < 1024) {
              return _TabletLayout(controller: this);
            }
            final leftWidth = width < 1280 ? 340.0 : 400.0;
            return _DesktopLayout(controller: this, leftPanelWidth: leftWidth);
          },
        ),
      ),
    );
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

Widget _stepTransition(
  Widget child,
  Animation<double> animation,
  bool goingForward,
) {
  final offsetBegin = goingForward
      ? const Offset(0.04, 0)
      : const Offset(-0.04, 0);
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: offsetBegin,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// TABLET LAYOUT  (800 – 1023 px)
// Single column, header bar, slim progress bar, centered content card
// ═════════════════════════════════════════════════════════════════════════════

class _TabletLayout extends StatelessWidget {
  final _WebOnboardingScreenState controller;
  const _TabletLayout({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;
    final progress = (c.currentStep + 1) / c.totalSteps;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: theme.cardColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                // Back button (or empty space to keep logo centred)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: c.currentStep > 0
                      ? InkWell(
                          onTap: c.back,
                          borderRadius: BorderRadius.circular(10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 17,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Logo
                Image.asset(
                  theme.brightness == Brightness.dark
                      ? 'assets/icons/app_logo_dark.png'
                      : 'assets/icons/app_logo.png',
                  height: 80,
                  width: 80,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.favorite_rounded,
                    color: theme.primaryColor,
                    size: 26,
                  ),
                ),
                // const SizedBox(width: 10),
                // Text(
                //   'Life Partner Again',
                //   style: GoogleFonts.outfit(
                //     fontSize: 17,
                //     fontWeight: FontWeight.w700,
                //     color: theme.textTheme.bodyLarge?.color,
                //     letterSpacing: -0.2,
                //   ),
                // ),
                const Spacer(),
                // Step badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${c.currentStep + 1} / ${c.totalSteps}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Segmented progress ───────────────────────────────────────────────
        _SegmentedProgressBar(
          currentStep: c.currentStep,
          totalSteps: c.totalSteps,
          progress: progress,
          color: theme.primaryColor,
          backgroundColor: theme.dividerColor,
        ),

        // ── Scrollable content ───────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        _stepTransition(child, anim, c.goingForward),
                    child: KeyedSubtree(
                      key: ValueKey(c.currentStep),
                      child: c.buildCurrentStep(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Continue button ──────────────────────────────────────────────────
        _ContinueButtonBar(controller: c, padding: 28),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DESKTOP LAYOUT  (1024 px+)
// Two-column: fixed left panel (brand + progress) + scrollable right panel
// ═════════════════════════════════════════════════════════════════════════════

class _DesktopLayout extends StatelessWidget {
  final _WebOnboardingScreenState controller;
  final double leftPanelWidth;
  const _DesktopLayout({
    required this.controller,
    required this.leftPanelWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LeftPanel(controller: controller, width: leftPanelWidth),
        Expanded(child: _RightPanel(controller: controller)),
      ],
    );
  }
}

// ─── Left Panel ──────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  final _WebOnboardingScreenState controller;
  final double width;
  const _LeftPanel({required this.controller, required this.width});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final primary = Theme.of(context).primaryColor;
    final progress = (c.currentStep + 1) / c.totalSteps;

    return Container(
      width: width,
      color: primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 44, 44, 0),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/icons/app_logo.png',
                  height: 80,
                  width: 80,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // ── Animated step info ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Step label
                  Text(
                    'STEP ${c.currentStep + 1} OF ${c.totalSteps}',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, 0.06),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: Align(
                      key: ValueKey('title_${c.currentStep}'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        c.getStepTitle(c.currentStep),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: width < 380 ? 30 : 34,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOut,
                      ),
                      child: child,
                    ),
                    child: Align(
                      key: ValueKey('desc_${c.currentStep}'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        c.getStepDescription(c.currentStep),
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 15,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 44),

                  // Segmented progress
                  _SegmentedProgressBar(
                    currentStep: c.currentStep,
                    totalSteps: c.totalSteps,
                    progress: progress,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    showPercentage: true,
                    percentageColor: Colors.white.withValues(alpha: 0.5),
                  ),

                  const SizedBox(height: 44),

                  // Back button
                  if (c.currentStep > 0) ...[_BackButton(onTap: c.back)],
                ],
              ),
            ),

            const Spacer(),

            // ── Bottom decoration ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 0, 44, 36),
              child: Text(
                '© Life Partner Again',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Right Panel ─────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  final _WebOnboardingScreenState controller;
  const _RightPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;

    return Container(
      color: theme.canvasColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Scrollable step content ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(48, 64, 48, 32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) =>
                          _stepTransition(child, anim, c.goingForward),
                      child: KeyedSubtree(
                        key: ValueKey(c.currentStep),
                        child: c.buildCurrentStep(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Sticky continue button ──────────────────────────────────────
          _ContinueButtonBar(controller: c, padding: 48),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

// ─── Segmented progress bar ───────────────────────────────────────────────────

class _SegmentedProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double progress;
  final Color color;
  final Color backgroundColor;
  final bool showPercentage;
  final Color? percentageColor;

  const _SegmentedProgressBar({
    required this.currentStep,
    required this.totalSteps,
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.showPercentage = false,
    this.percentageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isDone = index <= currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(right: index < totalSteps - 1 ? 3 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: isDone ? color : backgroundColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).round()}% complete',
            style: GoogleFonts.outfit(
              color: percentageColor ?? color.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Continue button bar ──────────────────────────────────────────────────────

class _ContinueButtonBar extends StatelessWidget {
  final _WebOnboardingScreenState controller;
  final double padding;
  const _ContinueButtonBar({required this.controller, required this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = controller;
    final isActive = c.canProceed && !c.isLoading;
    final label = c.currentStep == c.totalSteps - 1
        ? 'Set Partner Preferences'
        : 'Continue';

    return Container(
      decoration: BoxDecoration(
        color: theme.canvasColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      padding: EdgeInsets.fromLTRB(padding, 20, padding, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AnimatedOpacity(
            opacity: c.canProceed ? 1.0 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: MouseRegion(
                cursor: isActive
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: ElevatedButton(
                  onPressed: isActive ? c.next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.primaryColor,
                    disabledForegroundColor: theme.colorScheme.onPrimary,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: c.isLoading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.1,
                              ),
                            ),
                            if (c.currentStep < c.totalSteps - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 17),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Back button ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white.withValues(alpha: 0.65),
              size: 13,
            ),
            const SizedBox(width: 8),
            Text(
              'Previous step',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
