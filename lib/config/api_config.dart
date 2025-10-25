import 'dart:io';

class ApiConfig {
  // IMPORTANT: Set this to true when using emulator, false when using physical device
  static const bool _useEmulator = false;

  // Automatically detects emulator vs physical device
  // For emulator: uses 10.0.2.2
  // For physical device: uses your computer's local IP
  static String get baseUrl {
    if (Platform.isAndroid) {
      const String localIp =
          '10.9.31.173'; // Your computer's IP on local network
      const String emulatorIp = '10.0.2.2'; // Emulator special IP

      final ip = _useEmulator ? emulatorIp : localIp;
      return 'http://$ip:5000/api';
    }

    // Fallback for other platforms
    return 'http://10.9.31.173:5000/api';
  }

  // API Endpoints
  static const String health = '/health';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String uploadIdProof = '/upload/id-proof';
}
