import 'dart:io';

class ApiConfig {
  // IMPORTANT: Connection mode selection
  // Options: 'usb', 'wifi', 'emulator'
  static const String _connectionMode = 'usb'; // Set to 'usb' when using adb reverse

  // Automatically configures the correct endpoint
  // usb: uses localhost (requires: adb reverse tcp:5000 tcp:5000)
  // wifi: uses your computer's IP on local network
  // emulator: uses 10.0.2.2
  static String get baseUrl {
    if (Platform.isAndroid) {
      const String localIp = '10.9.31.173'; // Your computer's IP on WiFi
      const String emulatorIp = '10.0.2.2'; // Emulator special IP
      const String usbIp = 'localhost'; // USB connection via adb reverse

      final ip = _connectionMode == 'usb' 
          ? usbIp 
          : (_connectionMode == 'emulator' ? emulatorIp : localIp);
      final url = 'http://$ip:5000/api';
      print('📡 API Config - Connection Mode: $_connectionMode');
      print('📡 Using IP: $ip');
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
