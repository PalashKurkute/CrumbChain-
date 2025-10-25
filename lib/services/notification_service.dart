import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/notification.dart';

class NotificationService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Get all notifications for the current user
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Please login to view notifications'
        };
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        final notificationsList = (data['notifications'] as List)
            .map((json) => AppNotification.fromJson(json))
            .toList();
        
        return {
          'success': true,
          'notifications': notificationsList,
          'unreadCount': data['unreadCount'] ?? 0,
        };
      }
      
      return data;
    } catch (e) {
      print('Error fetching notifications: $e');
      return {
        'success': false,
        'message': 'Failed to fetch notifications: $e',
        'notifications': [],
        'unreadCount': 0
      };
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return 0;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (data['success'] == true) {
        return data['count'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required'
        };
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to mark notification as read: $e'
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required'
        };
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to mark all as read: $e'
      };
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required'
        };
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete notification: $e'
      };
    }
  }

  // Create mock notifications for testing (when backend is not ready)
  static List<AppNotification> getMockNotifications() {
    final now = DateTime.now();
    
    return [
      AppNotification(
        id: '1',
        userId: 'user123',
        type: 'approval_request',
        title: 'New Order Request',
        message: 'Ramesh Kumar wants to claim your food donation "Fresh Vegetables"',
        listingId: 'listing123',
        orderId: 'order123',
        relatedUserId: 'receiver123',
        relatedUserName: 'Ramesh Kumar',
        orderStatus: 'pending_approval',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: '2',
        userId: 'user123',
        type: 'order_status',
        title: 'Order Approved',
        message: 'Your order for "Rice and Dal" has been approved by the donor',
        listingId: 'listing456',
        orderId: 'order456',
        orderStatus: 'approved',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: '3',
        userId: 'user123',
        type: 'order_status',
        title: 'Order In Transit',
        message: 'Your order "Fruits and Snacks" is now in transit',
        listingId: 'listing789',
        orderId: 'order789',
        orderStatus: 'in_transit',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      AppNotification(
        id: '4',
        userId: 'user123',
        type: 'listing_claimed',
        title: 'Listing Claimed',
        message: 'Priya Sharma has claimed your listing "Bread and Milk"',
        listingId: 'listing321',
        relatedUserId: 'receiver456',
        relatedUserName: 'Priya Sharma',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: '5',
        userId: 'user123',
        type: 'order_status',
        title: 'Order Delivered',
        message: 'Your order "Cooked Food" has been delivered successfully',
        listingId: 'listing654',
        orderId: 'order654',
        orderStatus: 'delivered',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: '6',
        userId: 'user123',
        type: 'order_status',
        title: 'Order Completed',
        message: 'Your order has been marked as completed. Thank you for using CrumbChain!',
        listingId: 'listing987',
        orderId: 'order987',
        orderStatus: 'completed',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      AppNotification(
        id: '7',
        userId: 'user123',
        type: 'message',
        title: 'New Message',
        message: 'You have received a message from support team',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}
