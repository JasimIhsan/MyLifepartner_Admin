import 'package:flutter/material.dart';

class PublicWebBreakpoints {
  static const double mobile = 768;
  static const double desktop = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < desktop;
  static bool isDesktop(double width) => width >= desktop;
}

class ResponsiveWebContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWebContainer({
    super.key,
    required this.child,
    this.maxWidth = 1400,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = PublicWebBreakpoints.isMobile(width)
            ? width < 420
                  ? 18.0
                  : 22.0
            : PublicWebBreakpoints.isTablet(width)
            ? 36.0
            : 44.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding:
                  padding ??
                  EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
