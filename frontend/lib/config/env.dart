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

  // Google Sign-In Server Client ID
  static const String googleServerClientId =
      '856649629853-6ma089cfgf930e29mstdj9ga8g20jltj.apps.googleusercontent.com';
}
