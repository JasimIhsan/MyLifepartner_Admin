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
}
