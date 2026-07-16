import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/call_provider.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/providers/subscription_provider.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/services/zego_service.dart';
import 'package:life_partner_again/widgets/incoming_call_overlay.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:life_partner_again/core/app_router.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final RouteObserver<PageRoute> routeObserver =
    RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  ZegoService.instance.init();

  // Bootstrap auth BEFORE the app renders so GoRouter's first redirect
  // already has the correct isLoggedIn state, preventing the login screen
  // from flashing on web when the user manually changes the URL.
  final authProvider = AuthProvider();
  await authProvider.bootstrap();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatefulWidget {
  final AuthProvider authProvider;
  const MyApp({super.key, required this.authProvider});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;
  final ProfileRepository _profileRepo = ProfileRepository();
  late final AppLinks _appLinks = AppLinks();
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = widget.authProvider;
    _router = createRouter(_authProvider);
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
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => ImageAssetProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: MaterialApp.router(
        title: 'Life Partner Again',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: scaffoldMessengerKey,
        routerConfig: _router,

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
