class Env {
  static const String baseUrl = Env.isProduction
      ? 'https://api.lifepartneragain.ciltriq.com/api/user'
      : 'https://nonindividualistic-dilutely-glory.ngrok-free.dev/api/user';

  // Environment flags
  // isProduction => Siraj
  // !isProduction => Jasim
  static const bool isProduction = false;

  // ZEGOCLOUD — AppID only. AppSign is NEVER stored on the client.
  // Authentication uses backend-generated tokens from /api/user/zego/token.
  // Token renewal uses POST /api/user/zego/renew-token.
  static const int zegoAppId = 1331651742;

  // RevenueCat - Payment Gatway
  static const String revenueCatApiKey = 'goog_iPFGEdyRedFAtyobbTVSFapcuRW';

  // Google Sign-In Server Client ID (Android / Backend Verification)
  static const String googleServerClientId =
      '856649629853-6ma089cfgf930e29mstdj9ga8g20jltj.apps.googleusercontent.com';

  // Google Sign-In Web OAuth Client ID (Flutter Web GIS)
  static const String googleWebClientId =
      '856649629853-4ms5n5qt1aujob98co3gb5hse7hrkvun.apps.googleusercontent.com';

  // Google Sign-In iOS OAuth Client ID
  static const String googleIosClientId =
      '856649629853-4kgi1o2obtvfjrme7jkg79q6tiffhrfm.apps.googleusercontent.com';
}
