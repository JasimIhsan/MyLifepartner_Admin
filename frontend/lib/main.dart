import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen/splash_screen.dart';

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
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
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
            surface: AppColors.background,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: AppColors.background,
            centerTitle: true,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
