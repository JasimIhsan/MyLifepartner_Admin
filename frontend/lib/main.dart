import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:provider/provider.dart';

import 'screens/landing_screen/landing_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;
  final ProfileRepository _profileRepo = ProfileRepository();

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  late final AppLinks _appLinks = AppLinks();

  void _handleIncomingLinks() {
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _processUri(uri);
    });

    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _processUri(uri);
      },
      onError: (err) {
        debugPrint("Failed to handle incoming link: $err");
      },
    );
  }

  Future<void> _processUri(Uri uri) async {
    if (uri.scheme != 'mylifepartner' || uri.host != 'verify-email') {
      return;
    }

    final token = uri.queryParameters['token'];
    if (token == null) return;

    try {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Verifying email...')),
      );

      final result = await _profileRepo.verifyEmail(token);

      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Email verified successfully!'),
          backgroundColor: Colors.black,
        ),
      );
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MatchProvider())],
      child: MaterialApp(
        title: 'Life Partner Again',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
          ).copyWith(
            surface: Colors.white,
            surfaceTint: Colors.transparent,
            surfaceContainerLowest: Colors.white,
            surfaceContainerLow: Colors.white,
            surfaceContainer: Colors.white,
            surfaceContainerHigh: Colors.white,
            surfaceContainerHighest: Colors.white,
          ),
          useMaterial3: true,
          canvasColor: Colors.white,
          cardColor: Colors.white,
          dialogBackgroundColor: Colors.white,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
          ),
        ),
        home: const LandingScreen(),
      ),
    );
  }
}
