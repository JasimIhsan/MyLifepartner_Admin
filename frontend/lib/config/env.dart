class Env {
  static const String baseUrl = Env.isProduction
      ? 'https://backend.lifepartneragain.ciltriq.com/api'
      : 'https://nonindividualistic-dilutely-glory.ngrok-free.dev/api';

  // Environment flags
  // isProduction => Siraj
  // !isProduction => Jasim
  static const bool isProduction = true;
}
