import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class ListingService {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // Get stored token
  Future<String?> _getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Create a new listing
  Future<Map<String, dynamic>> createListing({
    required String foodType,
    required String quantity,
    required String dietaryTag,
    required String temperatureStatus,
    required String location,
    required String packagingType,
    String? description,
    String? datePrepared,
    String? pickupTime,
    bool isPaidDonation = false,
    double amount = 0,
    String? imageUrl,
  }) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.createListing}';
      print('🔗 Create Listing URL: $url');
      print('📤 Sending create listing request...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'foodType': foodType,
          'description': description ?? '',
          'quantity': quantity,
          'datePrepared': datePrepared,
          'dietaryTag': dietaryTag,
          'temperatureStatus': temperatureStatus,
          'location': location,
          'pickupTime': pickupTime,
          'packagingType': packagingType,
          'isPaidDonation': isPaidDonation,
          'amount': amount,
          'imageUrl': imageUrl ?? '',
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Listing created successfully',
          'data': data['data'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to create listing',
        };
      }
    } catch (e) {
      print('❌ Create listing error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get all listings or user's listings
  Future<Map<String, dynamic>> getListings({bool userOnly = false, String? status}) async {
    try {
      final token = await _getToken();

      // If userOnly is requested, token is required
      if (userOnly && token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      String url = '${ApiConfig.baseUrl}${ApiConfig.listings}';
      List<String> queryParams = [];
      
      if (userOnly) {
        queryParams.add('userOnly=true');
      }
      
      if (status != null) {
        queryParams.add('status=$status');
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      print('🔗 Get Listings URL: $url');

      // Build headers - include token if available, but don't require it for public browsing
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get listings',
        };
      }
    } catch (e) {
      print('❌ Get listings error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Get a specific listing by ID
  Future<Map<String, dynamic>> getListing(String listingId) async {
    try {
      final token = await _getToken();

      final url = '${ApiConfig.baseUrl}${ApiConfig.listings}/$listingId';
      print('🔗 Get Listing URL: $url');

      // Build headers - include token if available, but don't require it
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to get listing',
        };
      }
    } catch (e) {
      print('❌ Get listing error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Update a listing
  Future<Map<String, dynamic>> updateListing(
    String listingId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.listings}/$listingId';
      print('🔗 Update Listing URL: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Listing updated successfully',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update listing',
        };
      }
    } catch (e) {
      print('❌ Update listing error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Delete a listing
  Future<Map<String, dynamic>> deleteListing(String listingId) async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final url = '${ApiConfig.baseUrl}${ApiConfig.listings}/$listingId';
      print('🔗 Delete Listing URL: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Listing deleted successfully',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to delete listing',
        };
      }
    } catch (e) {
      print('❌ Delete listing error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
