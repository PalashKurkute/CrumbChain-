import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class RatingService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Submit a rating for a donor
  Future<Map<String, dynamic>> submitRating({
    required String listingId,
    required String donorId,
    required double rating,
    String? review,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to submit ratings'
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ratings/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'listingId': listingId,
          'donorId': donorId,
          'rating': rating,
          'review': review ?? '',
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to submit rating: $e'
      };
    }
  }

  // Check if user has already rated a listing
  Future<Map<String, dynamic>> checkRatingSubmitted(String listingId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to check ratings'
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ratings/check/$listingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to check rating: $e'
      };
    }
  }

  // Get all ratings for a donor
  Future<Map<String, dynamic>> getDonorRatings(String donorId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ratings/donor/$donorId'),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch ratings: $e'
      };
    }
  }
}
