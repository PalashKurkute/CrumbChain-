import 'dart:io';

class ApiConfig {
  // IMPORTANT: Set this to true when using emulator, false when using physical device
  // If you get 404 errors, try switching this value
  static const bool _useEmulator =
      false; // Set to false for physical device via USB

  // Automatically detects emulator vs physical device
  // For emulator: uses 10.0.2.2
  // For physical device: uses your computer's local IP
  static String get baseUrl {
    if (Platform.isAndroid) {
      const String localIp =
          '10.9.31.191'; // Your computer's IP on local network (UPDATED)
      const String emulatorIp = '10.0.2.2'; // Emulator special IP

      final ip = _useEmulator ? emulatorIp : localIp;
      final url = 'http://$ip:5000/api';
      print(
        '📡 API Config - Using ${_useEmulator ? "Emulator" : "Physical Device"} IP: $ip',
      );
      print('📡 Full baseUrl: $url');
      return url;
    }

    // Fallback for other platforms
    return 'http://10.105.149.166:5000/api';
  }

  // API Endpoints
  static const String health = '/health';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String uploadIdProof = '/upload/id-proof';
  static const String listings = '/listings';
  static const String createListing = '/listings';
  static const String getUserListings = '/listings?userOnly=true';
  static const String detectFood = '/detect-food';
}
