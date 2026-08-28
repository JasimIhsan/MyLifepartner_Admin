import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'app_tour_controller.dart';
import 'app_tour_step.dart';

class AppTourOverlay extends StatefulWidget {
  final String pageId;
  final List<AppTourStep> steps;
  final Widget child;
  final VoidCallback? onTourCompleted;
  final List<String>? dependsOn;
  final bool enabled;

  const AppTourOverlay({
    super.key,
    required this.pageId,
    required this.steps,
    required this.child,
    this.onTourCompleted,
    this.dependsOn,
    this.enabled = true,
  });

  @override
  State<AppTourOverlay> createState() => _AppTourOverlayState();
}

class _AppTourOverlayState extends State<AppTourOverlay>
    with SingleTickerProviderStateMixin {
  bool _isTourActive = false;
  int _currentStepIndex = 0;

  late AnimationController _animController;
  late Animation<double> _animCurve;

  RRect? _previousTargetRect;
  RRect? _currentTargetRect;

  OverlayEntry? _overlayEntry;
  StreamSubscription<String>? _dependencySubscription;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animCurve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _animController.addListener(() {
      if (mounted) {
        _overlayEntry?.markNeedsBuild();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartTour();
    });
  }

  @override
  void didUpdateWidget(AppTourOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !oldWidget.enabled) {
      _checkAndStartTour();
    }
  }

  @override
  void dispose() {
    _dependencySubscription?.cancel();
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      if (_overlayEntry!.mounted) {
        _overlayEntry!.remove();
      }
      _overlayEntry = null;
    }
  }

  Future<void> _checkAndStartTour() async {
    if (kIsWeb || widget.steps.isEmpty || !widget.enabled) return;

    final completed = await AppTourController.isTourCompleted(widget.pageId);
    if (completed || !mounted) return;

    if (widget.dependsOn != null && widget.dependsOn!.isNotEmpty) {
      for (final dep in widget.dependsOn!) {
        final depCompleted = await AppTourController.isTourCompleted(dep);
        if (!depCompleted) {
          // Listen for the dependency to complete
          _dependencySubscription ??= AppTourController.onTourCompleted.listen((completedPageId) {
            if (widget.dependsOn!.contains(completedPageId)) {
              _checkAndStartTour();
            }
          });
          return; // Wait for the event
        }
      }
    }

    _dependencySubscription?.cancel();

    // Delay slightly for initial layout rendering
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _startStep(0);
  }

  void _startStep(int index) {
    if (index < 0 || index >= widget.steps.length) {
      _finishTour();
      return;
    }

    final step = widget.steps[index];

    if (step.targetKey == null) {
      setState(() {
        _currentStepIndex = index;
        _previousTargetRect = _currentTargetRect ?? RRect.zero;
        _currentTargetRect = RRect.zero;
        _isTourActive = true;
      });

      if (_overlayEntry == null) {
        _overlayEntry = OverlayEntry(
          builder: (context) => _buildOverlayContent(),
        );
        Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
      } else {
        _overlayEntry?.markNeedsBuild();
      }

      _animController.forward(from: 0.0);
      return;
    }

    final targetContext = step.targetKey!.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
        curve: Curves.easeInOut,
      ).catchError((_) {});
    }

    final rect = _calculateTargetRRect(step);

    if (rect == null) {
      // Retry in next frame if render box wasn't ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startStep(index);
      });
      return;
    }

    setState(() {
      _currentStepIndex = index;
      _previousTargetRect = _currentTargetRect ?? rect;
      _currentTargetRect = rect;
      _isTourActive = true;
    });

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _buildOverlayContent(),
      );
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } else {
      _overlayEntry?.markNeedsBuild();
    }

    _animController.forward(from: 0.0);
  }

  RRect? _calculateTargetRRect(AppTourStep step) {
    if (step.targetKey == null) return RRect.zero;
    final targetContext = step.targetKey!.currentContext;
    if (targetContext == null) return null;

    final targetRenderBox = targetContext.findRenderObject() as RenderBox?;
    if (targetRenderBox == null || !targetRenderBox.hasSize) return null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final overlayRenderBox = overlay?.context.findRenderObject() as RenderBox?;
    if (overlayRenderBox == null) return null;

    final offset = targetRenderBox.localToGlobal(Offset.zero, ancestor: overlayRenderBox);
    final size = targetRenderBox.size;

    final inflatedRect = Rect.fromLTWH(
      offset.dx - step.spotlightPadding.left,
      offset.dy - step.spotlightPadding.top,
      size.width + step.spotlightPadding.horizontal,
      size.height + step.spotlightPadding.vertical,
    );

    return step.borderRadius.toRRect(inflatedRect);
  }

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      _startStep(_currentStepIndex + 1);
    } else {
      _finishTour();
    }
  }

  void _skipTour() {
    _finishTour();
  }

  Future<void> _finishTour() async {
    setState(() {
      _isTourActive = false;
    });
    _removeOverlay();
    await AppTourController.markTourCompleted(widget.pageId);
    widget.onTourCompleted?.call();
  }

  RRect _getAnimatedRect() {
    // Dynamically recalculate current target rect to track moving/animating widgets
    if (_isTourActive) {
      final step = widget.steps[_currentStepIndex];
      final dynamicRect = _calculateTargetRRect(step);
      if (dynamicRect != null) {
        _currentTargetRect = dynamicRect;
      }
    }

    if (_previousTargetRect == null || _currentTargetRect == null) {
      return RRect.zero;
    }

    final progress = _animCurve.value;
    return RRect.lerp(_previousTargetRect, _currentTargetRect, progress) ??
        _currentTargetRect!;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  Widget _buildOverlayContent() {
    final animatedRRect = _getAnimatedRect();
    final step = widget.steps[_currentStepIndex];
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Custom Painter for Backdrop Dim & Animated Spotlight Cutout
            CustomPaint(
              size: screenSize,
              painter: _SpotlightPainter(
                spotlightRect: animatedRRect,
                overlayColor: isDark
                    ? const Color(0xDC090D16)
                    : const Color(0xB3000000),
                accentColor: AppColors.primary,
              ),
            ),

            // Tap blocker on dimmed background
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const SizedBox.expand(),
            ),

            // Dynamically positioned Info Card
            _buildPositionedInfoCard(step, animatedRRect, screenSize, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedInfoCard(
    AppTourStep step,
    RRect spotlightRRect,
    Size screenSize,
    bool isDark,
  ) {
    if (step.targetKey == null || spotlightRRect == RRect.zero) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320.0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: _buildInfoCardContent(step, isDark),
            ),
          ),
        ),
      );
    }

    const cardWidth = 320.0;
    const padding = 16.0;

    final targetRect = spotlightRRect.outerRect;
    final spaceBelow = screenSize.height - targetRect.bottom;

    bool placeBelow;
    if (step.preferredPosition == TourCardPosition.top) {
      placeBelow = false;
    } else if (step.preferredPosition == TourCardPosition.bottom) {
      placeBelow = true;
    } else {
      placeBelow = spaceBelow >= 210;
    }

    double topPos;
    if (placeBelow) {
      topPos = (targetRect.bottom + 14.0).clamp(padding, screenSize.height - 240);
    } else {
      topPos = (targetRect.top - 210.0).clamp(padding, screenSize.height - 240);
    }

    double leftPos = targetRect.center.dx - (cardWidth / 2);
    leftPos = leftPos.clamp(padding, screenSize.width - cardWidth - padding);

    return Positioned(
      top: topPos,
      left: leftPos,
      width: cardWidth,
      child: FadeTransition(
        opacity: _animCurve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(_animCurve),
          child: _buildInfoCardContent(step, isDark),
        ),
      ),
    );
  }

  Widget _buildInfoCardContent(AppTourStep step, bool isDark) {
    final totalSteps = widget.steps.length;
    final currentNumber = _currentStepIndex + 1;
    final isLastStep = _currentStepIndex == totalSteps - 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xEE1E2430)
                : const Color(0xF7FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3D000000),
                blurRadius: 24,
                spreadRadius: 2,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Step Indicator Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Step $currentNumber of $totalSteps',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _skipTour,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                step.title,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                step.description,
                style: TextStyle(
                  color: isDark ? const Color(0xFFB0B8C4) : AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),

              if (step.customContent != null) ...[
                const SizedBox(height: 12),
                step.customContent!,
              ],
              const SizedBox(height: 18),

              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skipTour,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isLastStep ? 'Done' : 'Next',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isLastStep) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter to draw dim backdrop with rounded rectangular spotlight cutout
class _SpotlightPainter extends CustomPainter {
  final RRect spotlightRect;
  final Color overlayColor;
  final Color accentColor;

  _SpotlightPainter({
    required this.spotlightRect,
    required this.overlayColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = overlayColor;

    // Draw background path with cutout spotlight
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final spotlightPath = Path()..addRRect(spotlightRect);

    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      spotlightPath,
    );

    canvas.drawPath(combinedPath, backgroundPaint);

    // Draw glowing border around the cutout target
    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(spotlightRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.spotlightRect != spotlightRect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.accentColor != accentColor;
  }
}
