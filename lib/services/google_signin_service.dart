import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Sign in with Google
  Future<User?> signInWithGoogle(String userType) async {
    try {
      print('🔍 Starting Google Sign-In...');

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Google Sign-In cancelled by user');
        return null; // User cancelled
      }

      print('✅ Google Sign-In successful: ${googleUser.email}');

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('📤 Sending to backend...');

      // Send to backend
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/google-signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
          'userType': userType, // 'donor' or 'receiver'
        }),
      );

      print('📥 Backend response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Store token
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);
          print('💾 Token saved');
        }

        // Create user object
        final user = User(
          id: data['user']['_id'] ?? data['user']['id'],
          email: data['user']['email'],
          fullName: data['user']['full_name'] ?? googleUser.displayName ?? '',
          userType: data['user']['user_type'] ?? userType,
        );

        print('✅ User created: ${user.email}');
        return user;
      } else {
        print('❌ Backend error: ${response.body}');
        throw Exception(
          'Failed to authenticate with backend: ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Google Sign-In error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _storage.delete(key: 'auth_token');
      print('✅ Google Sign-Out successful');
    } catch (e) {
      print('❌ Google Sign-Out error: $e');
      rethrow;
    }
  }

  // Check if user is already signed in
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}
