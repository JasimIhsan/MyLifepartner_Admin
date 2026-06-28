class Env {
  static const String baseUrl = Env.isProduction
      ? 'https://mudfish-welcomed-guinea.ngrok-free.app/api'
      : 'https://nonindividualistic-dilutely-glory.ngrok-free.dev/api';

  // Environment flags
  // isProduction => Siraj
  // !isProduction => Jasim
  static const bool isProduction = false;

  // ZEGOCLOUD — populate from https://console.zegocloud.com/
  static const int zegoAppId = 1331651742; // Replace with your AppID
  static const String zegoAppSign =
      '64d06b939f5431ce808c6236114075869ee1082ee1d44bc1e0f5030b254f6438'; // Replace with your AppSign
  static const String revenueCatApiKey = 'test_XpBpMyOCaRGpgYiYdlQzzfVGWQP';
}
