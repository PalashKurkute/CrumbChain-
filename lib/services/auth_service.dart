import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Sign up new user
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String fullName,
    required String userType,
    String? idProofPath,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.register}';
      print('🔗 Signup URL: $url');
      print('📤 Sending signup request for: $email, type: $userType');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': fullName,
          'userType': userType,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - check if backend server is running');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Save token and user data
          await _storage.write(key: _tokenKey, value: data['data']['token']);
          await _storage.write(
            key: _userKey,
            value: json.encode(data['data']['user']),
          );

          print('✅ Signup successful for: ${data['data']['user']['email']}');

          return {
            'success': true,
            'user': User.fromJson(data['data']['user']),
            'message': data['message'],
          };
        } else {
          print('❌ Signup failed: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Signup failed',
          };
        }
      } else if (response.statusCode == 409) {
        // Email already exists
        final error = json.decode(response.body);
        print('❌ Email already registered: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Email already registered',
        };
      } else if (response.statusCode >= 500) {
        print('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
        };
      } else {
        final error = json.decode(response.body);
        print('❌ Signup error: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      print('❌ Signup exception: $e');
      String errorMessage = 'Connection error';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout - check if backend is running at ${ApiConfig.baseUrl}';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Check your network and backend URL.';
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.login}';
      print('🔗 Login URL: $url');
      print('📤 Sending login request for: $email');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout - check if backend server is running');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Save token and user data
          await _storage.write(key: _tokenKey, value: data['data']['token']);
          await _storage.write(
            key: _userKey,
            value: json.encode(data['data']['user']),
          );

          print('✅ Login successful for: ${data['data']['user']['email']}');

          return {
            'success': true,
            'user': User.fromJson(data['data']['user']),
            'message': data['message'],
          };
        } else {
          print('❌ Login failed: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Login failed',
          };
        }
      } else if (response.statusCode == 401) {
        final error = json.decode(response.body);
        print('❌ Authentication failed: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Invalid email or password',
        };
      } else if (response.statusCode >= 500) {
        print('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
        };
      } else {
        final error = json.decode(response.body);
        print('❌ Login error: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('❌ Login exception: $e');
      String errorMessage = 'Connection error';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout - check if backend is running at ${ApiConfig.baseUrl}';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Check your network and backend URL.';
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get stored user data
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // Get current user from stored data
  Future<User?> getCurrentUser() async {
    try {
      final token = await getToken();
      final userJson = await _storage.read(key: _userKey);

      if (token != null && userJson != null) {
        final userData = json.decode(userJson);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Get user profile from API
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'user': User.fromJson(data['user'])};
      } else {
        return {'success': false, 'message': 'Failed to get profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }
}
