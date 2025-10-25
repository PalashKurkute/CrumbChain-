import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class OrderService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Claim a listing
  Future<Map<String, dynamic>> claimListing(String listingId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to claim listings'
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders/claim/$listingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to claim listing: $e'
      };
    }
  }

  // Approve an order (donor approves receiver's claim)
  Future<Map<String, dynamic>> approveOrder(String listingId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to approve orders'
        };
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/orders/$listingId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to approve order: $e'
      };
    }
  }

  // Update order status (for live tracking simulation)
  Future<Map<String, dynamic>> updateOrderStatus(
    String listingId,
    String newStatus,
  ) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required'
        };
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/orders/$listingId/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'orderStatus': newStatus,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update order status: $e'
      };
    }
  }

  // Get all orders (order history)
  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to view orders'
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/my-orders'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch orders: $e'
      };
    }
  }

  // Get active orders for live tracking
  Future<Map<String, dynamic>> getActiveOrders() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to view active orders'
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/active'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to fetch active orders: $e'
      };
    }
  }

  // Delete an order (receiver can delete pending orders)
  Future<Map<String, dynamic>> deleteOrder(String orderId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to delete orders'
        };
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/orders/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete order: $e'
      };
    }
  }

  // Get status display name
  static String getStatusDisplayName(String status) {
    switch (status) {
      case 'pending_approval':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'in_transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  // Get status color
  static int getStatusColor(String status) {
    switch (status) {
      case 'pending_approval':
        return 0xFFFFA500; // Orange
      case 'approved':
        return 0xFF4CAF50; // Green
      case 'in_transit':
        return 0xFF2196F3; // Blue
      case 'out_for_delivery':
        return 0xFF9C27B0; // Purple
      case 'delivered':
        return 0xFF00BCD4; // Cyan
      case 'completed':
        return 0xFF8BC34A; // Light Green
      default:
        return 0xFF757575; // Grey
    }
  }

  // Get status icon
  static String getStatusIcon(String status) {
    switch (status) {
      case 'pending_approval':
        return '⏳';
      case 'approved':
        return '✅';
      case 'in_transit':
        return '🚚';
      case 'out_for_delivery':
        return '📦';
      case 'delivered':
        return '🏁';
      case 'completed':
        return '✨';
      default:
        return '📋';
    }
  }
}
