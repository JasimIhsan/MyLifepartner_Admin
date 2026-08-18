import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  Color _fill(BuildContext context, [double alpha = 0.1]) {
    return Theme.of(context).disabledColor.withValues(alpha: alpha);
  }

  Widget _box(
    BuildContext context, {
    double width = double.infinity,
    double height = 16,
    double radius = 8,
  }) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: _fill(context),
            borderRadius: BorderRadius.circular(radius),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 650.ms, begin: 0.45, curve: Curves.easeInOut);
  }

  Widget _circle(BuildContext context, double size) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _fill(context),
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fadeIn(duration: 650.ms, begin: 0.45, curve: Curves.easeInOut);
  }

  Widget _sectionTitle(BuildContext context, {double width = 92}) {
    return _box(context, width: width, height: 12, radius: 4);
  }

  Widget _photoBlock(BuildContext context, {double aspectRatio = 16 / 10}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _box(context, radius: 12),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.78,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _box(context, radius: 0),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.52),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _box(context, width: 82, height: 24, radius: 999),
                const SizedBox(height: 12),
                _box(context, width: 220, height: 30, radius: 7),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _box(context, width: 96, height: 14, radius: 5),
                    const SizedBox(width: 12),
                    _box(context, width: 78, height: 14, radius: 5),
                    const SizedBox(width: 12),
                    _box(context, width: 88, height: 14, radius: 5),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _about(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, width: 56),
        const SizedBox(height: 14),
        _box(context, height: 14, radius: 5),
        const SizedBox(height: 8),
        _box(context, height: 14, radius: 5),
        const SizedBox(height: 8),
        _box(context, width: 260, height: 14, radius: 5),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _basics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, width: 82),
        const SizedBox(height: 12),
        for (int i = 0; i < 4; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                _circle(context, 22),
                const SizedBox(width: 16),
                Expanded(child: _box(context, height: 14, radius: 5)),
                const SizedBox(width: 42),
                _box(context, width: i == 3 ? 112 : 78, height: 14, radius: 5),
              ],
            ),
          ),
          if (i != 3)
            Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withValues(alpha: 0.72),
            ),
        ],
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _cardGrid(BuildContext context, {bool compact = false}) {
    return Row(
      children: [
        Expanded(child: _infoCard(context, compact: compact)),
        const SizedBox(width: 10),
        Expanded(child: _infoCard(context, compact: compact)),
      ],
    );
  }

  Widget _infoCard(BuildContext context, {bool compact = false}) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 68 : 92),
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _circle(context, 22),
          SizedBox(height: compact ? 7 : 12),
          _box(context, width: 72, height: compact ? 11 : 13, radius: 4),
          const SizedBox(height: 5),
          _box(context, height: compact ? 13 : 14, radius: 5),
        ],
      ),
    );
  }

  Widget _educationCareer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, width: 142),
        const SizedBox(height: 12),
        _cardGrid(context),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _lifestyle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, width: 76),
        const SizedBox(height: 12),
        _cardGrid(context, compact: true),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _languages(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, width: 82),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _box(context, width: 108, height: 40, radius: 999),
            _box(context, width: 96, height: 40, radius: 999),
            _box(context, width: 104, height: 40, radius: 999),
          ],
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _lookingFor(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, width: 92),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _circle(context, 22),
              const SizedBox(width: 14),
              Expanded(child: _box(context, height: 16, radius: 5)),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _actionBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final smallButtonColor = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFFBF8F8);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _actionButton(context, color: smallButtonColor, width: 54),
          const SizedBox(width: 12),
          Expanded(child: _actionButton(context, color: theme.primaryColor)),
          const SizedBox(width: 12),
          _actionButton(context, color: smallButtonColor, width: 54),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required Color color,
    double? width,
  }) {
    final isPrimary = color == Theme.of(context).primaryColor;

    return Container(
      width: width,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPrimary ? 0.5 : 1),
        shape: width == null ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: width == null ? BorderRadius.circular(100) : null,
        border: width == null
            ? null
            : Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
              ),
      ),
      child: Center(
        child: _box(
          context,
          width: width == null ? 116 : 24,
          height: width == null ? 14 : 24,
          radius: width == null ? 5 : 999,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _hero(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _about(context),
                            _photoBlock(context),
                            _basics(context),
                            _educationCareer(context),
                            _photoBlock(context),
                            _lifestyle(context),
                            _languages(context),
                            _lookingFor(context),
                            SizedBox(
                              height:
                                  118 + MediaQuery.of(context).padding.bottom,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: _circle(context, 44),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _actionBar(context)),
      ],
    );
  }
}
