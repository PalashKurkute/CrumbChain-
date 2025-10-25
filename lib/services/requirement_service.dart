import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/requirement.dart';
import '../config/api_config.dart';

class RequirementService {
  // Get all requirements (public endpoint for donors to browse)
  static Future<List<Requirement>> getRequirements({
    String? status,
    String? organizationType,
  }) async {
    try {
      var url = Uri.parse('${ApiConfig.baseUrl}/requirements');
      
      // Add query parameters
      Map<String, String> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (organizationType != null) queryParams['organizationType'] = organizationType;
      
      if (queryParams.isNotEmpty) {
        url = url.replace(queryParameters: queryParams);
      }

      final response = await http.get(url);

      print('📡 GET /requirements - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          List<dynamic> requirementsJson = data['data']['requirements'];
          List<Requirement> requirements = requirementsJson
              .map((json) => Requirement.fromJson(json))
              .toList();
          print('✅ Fetched ${requirements.length} requirements');
          return requirements;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch requirements');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch requirements');
      }
    } catch (e) {
      print('❌ Error fetching requirements: $e');
      rethrow;
    }
  }

  // Get a single requirement by ID (public endpoint)
  static Future<Requirement> getRequirement(String requirementId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/requirements/$requirementId');
      final response = await http.get(url);

      print('📡 GET /requirements/$requirementId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Requirement.fromJson(data['data']['requirement']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch requirement');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch requirement');
      }
    } catch (e) {
      print('❌ Error fetching requirement: $e');
      rethrow;
    }
  }

  // Create a new requirement (requires authentication)
  static Future<String> createRequirement(
    String token,
    Map<String, dynamic> requirementData,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/requirements');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requirementData),
      );

      print('📡 POST /requirements - Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['requirementId'];
        } else {
          throw Exception(data['message'] ?? 'Failed to create requirement');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create requirement');
      }
    } catch (e) {
      print('❌ Error creating requirement: $e');
      rethrow;
    }
  }

  // Update a requirement (requires authentication)
  static Future<void> updateRequirement(
    String token,
    String requirementId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/requirements/$requirementId');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      print('📡 PUT /requirements/$requirementId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to update requirement');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update requirement');
      }
    } catch (e) {
      print('❌ Error updating requirement: $e');
      rethrow;
    }
  }

  // Delete a requirement (requires authentication)
  static Future<void> deleteRequirement(
    String token,
    String requirementId,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/requirements/$requirementId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 DELETE /requirements/$requirementId - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Failed to delete requirement');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete requirement');
      }
    } catch (e) {
      print('❌ Error deleting requirement: $e');
      rethrow;
    }
  }
}
