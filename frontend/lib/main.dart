import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_router.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/providers/call_provider.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/providers/discovery_provider.dart';
import 'package:life_partner_again/providers/image_asset_provider.dart';
import 'package:life_partner_again/providers/location_provider.dart';
import 'package:life_partner_again/providers/match_provider.dart';
import 'package:life_partner_again/providers/notification_provider.dart';
import 'package:life_partner_again/providers/subscription_provider.dart';
import 'package:life_partner_again/providers/transaction_provider.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/services/zego_service.dart';
import 'package:life_partner_again/widgets/incoming_call_overlay.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  debugPrint("🚀 [INIT STEP 1] FlutterBinding initializing...");
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  debugPrint("✅ [INIT STEP 1 DONE] FlutterBinding & Orientations configured.");

  debugPrint("🚀 [INIT STEP 2] Initializing Zego Cloud Service...");
  try {
    ZegoService.instance.init();
    debugPrint("✅ [INIT STEP 2 DONE] Zego Cloud Service initialized.");
  } catch (e, stack) {
    debugPrint(
      "❌ [INIT STEP 2 ERROR] Zego Cloud Service initialization failed: $e\n$stack",
    );
  }

  debugPrint("🚀 [INIT STEP 3] Initializing Firebase Core & Options...");
  try {
    if (Firebase.apps.isEmpty) {
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint(
        "✅ [INIT STEP 3 DONE] Firebase app '${app.name}' initialized (Project: ${app.options.projectId}).",
      );
    } else {
      debugPrint(
        "ℹ️ [INIT STEP 3 INFO] Firebase app already initialized natively.",
      );
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      debugPrint(
        "ℹ️ [INIT STEP 3 INFO] Firebase app already initialized natively (duplicate-app caught).",
      );
    } else {
      debugPrint("❌ [INIT STEP 3 ERROR] Firebase initialization failed: $e");
    }
  } catch (e, stack) {
    debugPrint("❌ [INIT STEP 3 ERROR] Unexpected Firebase error: $e\n$stack");
  }

  // Removed: FirebaseNotificationService initialization
  // Removed: authProvider.bootstrap() - This will now happen in SplashScreen

  debugPrint("🚀 [INIT STEP 4] Launching Flutter App UI (runApp)...");
  final authProvider = AuthProvider(); // Uninitialized, triggers splash
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
    final validSchemes = ['mylifepartner', 'lifepartneragain'];
    if (!validSchemes.contains(uri.scheme)) {
      return;
    }

    if (uri.host == 'account-deleted') {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Account deletion verified. Logging out...'),
          backgroundColor: Colors.black,
        ),
      );
      await ApiService.logoutAndRedirect();
      return;
    }

    if (uri.host != 'verify-email') {
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
        ChangeNotifierProvider(create: (_) => ChatProvider()..initListeners(), lazy: false),
        ChangeNotifierProvider(create: (_) => CallProvider()..initListeners(), lazy: false),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => DiscoveryProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..initialize(),
        ),
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
          ).copyWith(surface: Colors.white, surfaceTint: Colors.transparent),

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
          return Stack(children: [child!, const IncomingCallOverlay()]);
        },
      ),
    );
  }
}
