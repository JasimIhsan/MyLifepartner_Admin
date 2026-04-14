class Env {
  static const String baseUrl = Env.isProduction
      ? 'https://mudfish-welcomed-guinea.ngrok-free.app/api'
      : 'https://nonindividualistic-dilutely-glory.ngrok-free.dev/api';

  // Environment flags
  // isProduction => Siraj
  // !isProduction => Jasim
  static const bool isProduction = true;

  // ZEGOCLOUD — populate from https://console.zegocloud.com/
  static const int zegoAppId = 1140904980; // Replace with your AppID
  static const String zegoAppSign =
      '97127e2582e92a5ce87a8f6609d81acbe72199e6a33ee7978a0430facd2fa12a'; // Replace with your AppSign
}
