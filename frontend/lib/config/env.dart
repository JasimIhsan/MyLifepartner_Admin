class Env {
  // Root API origin (no path suffix) — used to build specific endpoint URLs.
  static const String _apiRoot = isProduction
      ? 'https://api.lifepartneragain.ciltriq.com'
      : 'https://nonindividualistic-dilutely-glory.ngrok-free.dev';

  static const String baseUrl = '$_apiRoot/api/user';

  // Environment flags
  // isProduction => Siraj
  // !isProduction => Jasim
  static const bool isProduction = true;

  // ZEGOCLOUD — AppID only. AppSign is NEVER stored on the client.
  // Authentication uses backend-generated tokens from /api/user/zego/token.
  // Token renewal uses POST /api/user/zego/renew-token.
  static const int zegoAppId = 1331651742;

  // RevenueCat - Payment Gatway
  static const String revenueCatApiKey = 'goog_iPFGEdyRedFAtyobbTVSFapcuRW';

  // Google Sign-In Server Client ID (Android / Backend Verification)
  static const String googleServerClientId = isProduction
      ? '856649629853-8q5tb42lfl93mr9vdl8n34mcuhh34ahb.apps.googleusercontent.com'
      : '856649629853-6ma089cfgf930e29mstdj9ga8g20jltj.apps.googleusercontent.com';

  // Google Sign-In Web OAuth Client ID (Flutter Web GIS)
  static const String googleWebClientId =
      '856649629853-4ms5n5qt1aujob98co3gb5hse7hrkvun.apps.googleusercontent.com';

  // Google Sign-In iOS OAuth Client ID
  static const String googleIosClientId =
      '856649629853-4kgi1o2obtvfjrme7jkg79q6tiffhrfm.apps.googleusercontent.com';

  // Apple Sign In — Android redirect URI.
  // (Web uses https://life-partner-again.vercel.app/ directly).
  // MUST match exactly what is registered in Apple Developer Console:
  //   Identifiers → [Service ID: com.premiumglobalcorp.lifepartneragain.web]
  //   → Sign In with Apple → Website URLs → Return URLs
  // For dev: register nonindividualistic-dilutely-glory.ngrok-free.dev in Apple Console.
  // For prod: register api.lifepartneragain.ciltriq.com in Apple Console.
  static const String appleRedirectUri =
      '$_apiRoot/api/user/oauth/apple/callback';
}
