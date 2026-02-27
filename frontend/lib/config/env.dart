class Env {
  // API base URLs
  static const String ipUrl = Env.isProduction
      ? 'https://mudfish-welcomed-guinea.ngrok-free.app/api'
      : 'http://192.168.1.27:3000/api';
  static const String localUrl = Env.isProduction
      ? 'https://mudfish-welcomed-guinea.ngrok-free.app/api'
      : 'http://localhost:3000/api';

  // Environment flags
  static const bool isProduction = false;
}
