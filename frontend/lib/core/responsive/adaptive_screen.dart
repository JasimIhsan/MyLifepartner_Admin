import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdaptiveScreen extends StatelessWidget {
  final Widget mobile;
  final Widget web;

  const AdaptiveScreen({
    super.key,
    required this.mobile,
    required this.web,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!kIsWeb) {
          return mobile;
        }

        if (constraints.maxWidth < 800) {
          return mobile;
        }

        return web;
      },
    );
  }
}
