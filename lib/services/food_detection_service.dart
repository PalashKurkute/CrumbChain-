import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class FoodDetectionService {
  final _storage = const FlutterSecureStorage();

  /// Detect food type from image using ML model
  /// Uses V2 endpoint with PyTorch EfficientNetB2 (80 Indian foods, 72%+ accuracy)
  Future<Map<String, dynamic>> detectFood(File imageFile) async {
    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Use new V2 endpoint with improved PyTorch model
      final url = '${ApiConfig.baseUrl}${ApiConfig.detectFoodV2}';
      print('🔗 Food Detection URL (V2 - PyTorch): $url');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();

      var multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
      );

      request.files.add(multipartFile);

      print('📤 Sending food detection request...');

      // Send request
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Connection timeout - check if backend server is running',
          );
        },
      );

      // Get response
      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          print(
            '✅ Food detected: ${data['data']['foodName']} (Confidence: ${data['data']['confidence']})',
          );

          // Log top 3 predictions if available (V2 endpoint feature)
          if (data['data']['top3Predictions'] != null) {
            print('📊 Top 3 predictions:');
            for (var pred in data['data']['top3Predictions']) {
              print('   - ${pred['foodName']}: ${pred['confidence']}');
            }
          }

          return {
            'success': true,
            'foodName': data['data']['foodName'],
            'confidence': data['data']['confidence'],
            'message': data['data']['message'],
            'top3Predictions':
                data['data']['top3Predictions'], // New field from V2
            'modelVersion': data['data']['modelVersion'], // New field from V2
          };
        } else {
          print('❌ Food detection failed: ${data['message']}');
          return {
            'success': false,
            'message': data['message'] ?? 'Food detection failed',
          };
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized - token may be invalid');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else if (response.statusCode >= 500) {
        print('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
        };
      } else {
        final error = json.decode(response.body);
        print('❌ Food detection error: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Food detection failed',
        };
      }
    } catch (e) {
      print('❌ Food detection exception: $e');
      String errorMessage = 'Connection error';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout - check if backend is running';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Cannot connect to server. Check your network.';
      }
      return {'success': false, 'message': errorMessage};
    }
  }
}
