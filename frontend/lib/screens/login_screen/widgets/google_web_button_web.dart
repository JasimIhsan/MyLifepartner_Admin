import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web_only;

Widget buildGoogleWebButton({required double minimumWidth}) {
  return web_only.renderButton(
    configuration: web_only.GSIButtonConfiguration(
      minimumWidth: minimumWidth,
    ),
  );
}
