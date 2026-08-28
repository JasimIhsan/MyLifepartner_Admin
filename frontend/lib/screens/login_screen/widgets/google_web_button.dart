import 'package:flutter/material.dart';
import 'google_web_button_stub.dart'
    if (dart.library.js_interop) 'google_web_button_web.dart'
    if (dart.library.html) 'google_web_button_web.dart';

Widget getGoogleWebButton({required double minimumWidth}) {
  return buildGoogleWebButton(minimumWidth: minimumWidth);
}
