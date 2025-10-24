class ApiConfig {
  // Change this to your computer's IP address when testing on physical device
  // For emulator: use 10.0.2.2
  // For physical device: use your computer's local IP (e.g., 192.168.1.100)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // API Endpoints
  static const String health = '/health';
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String uploadIdProof = '/upload/id-proof';
}
