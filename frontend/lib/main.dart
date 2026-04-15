import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/providers/call_provider.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/providers/match_provider.dart';
import 'package:mylifepartner/screens/landing_screen/landing_screen.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:mylifepartner/providers/subscription_provider.dart';
import 'package:mylifepartner/providers/image_asset_provider.dart';
import 'package:mylifepartner/services/zego_service.dart';
import 'package:mylifepartner/widgets/incoming_call_overlay.dart';
import 'package:provider/provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final RouteObserver<PageRoute> routeObserver =
    RouteObserver<PageRoute>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ZegoService.instance.init();
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
  late final AppLinks _appLinks = AppLinks();

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
      providers: [
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ImageAssetProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: MaterialApp(
        title: 'Life Partner Again',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],

        theme: ThemeData(
          useMaterial3: true,

          // Prevent gray elevation tint from Material 3
          applyElevationOverlayColor: false,

          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ).copyWith(
            surface: Colors.white,
            surfaceTint: Colors.transparent,
          ),

          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
          cardColor: Colors.white,
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),

          textTheme: GoogleFonts.poppinsTextTheme(),

          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
          ),
        ),

        home: const LandingScreen(),
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              const IncomingCallOverlay(),
            ],
          );
        },
      ),
    );
  }
}
