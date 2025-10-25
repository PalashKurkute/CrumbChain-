class AppNotification {
  final String id;
  final String userId;
  final String type; // 'order_status', 'listing_claimed', 'approval_request', 'message'
  final String title;
  final String message;
  final String? listingId;
  final String? orderId;
  final String? relatedUserId;
  final String? relatedUserName;
  final String? orderStatus;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.listingId,
    this.orderId,
    this.relatedUserId,
    this.relatedUserName,
    this.orderStatus,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] as String? ?? json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      listingId: json['listingId'] as String?,
      orderId: json['orderId'] as String?,
      relatedUserId: json['relatedUserId'] as String?,
      relatedUserName: json['relatedUserName'] as String?,
      orderStatus: json['orderStatus'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      if (listingId != null) 'listingId': listingId,
      if (orderId != null) 'orderId': orderId,
      if (relatedUserId != null) 'relatedUserId': relatedUserId,
      if (relatedUserName != null) 'relatedUserName': relatedUserName,
      if (orderStatus != null) 'orderStatus': orderStatus,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Get notification icon based on type
  String get icon {
    switch (type) {
      case 'order_status':
        return getOrderStatusIcon(orderStatus ?? '');
      case 'listing_claimed':
        return '🔔';
      case 'approval_request':
        return '⏳';
      case 'message':
        return '💬';
      case 'reward_earned':
        return '🎉';
      case 'rating_received':
        return '⭐';
      default:
        return '📢';
    }
  }

  // Get notification color based on type
  int get color {
    switch (type) {
      case 'order_status':
        return getOrderStatusColor(orderStatus ?? '');
      case 'listing_claimed':
        return 0xFF2196F3; // Blue
      case 'approval_request':
        return 0xFFFFA500; // Orange
      case 'message':
        return 0xFF4CAF50; // Green
      case 'reward_earned':
        return 0xFFFFD700; // Gold
      case 'rating_received':
        return 0xFFFFA500; // Orange/Amber
      default:
        return 0xFF757575; // Grey
    }
  }

  // Helper methods for order status
  static String getOrderStatusIcon(String status) {
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

  static int getOrderStatusColor(String status) {
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

  // Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
