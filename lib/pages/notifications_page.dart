import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../widgets/common_footer.dart';
import 'listing_tracker_page.dart';
import 'live_order_tracker_page.dart';
import 'order_history_page.dart';

class NotificationsPage extends StatefulWidget {
  final User? user;

  const NotificationsPage({super.key, this.user});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final OrderService _orderService = OrderService();
  List<AppNotification> _notifications = [];
  List<AppNotification> _filteredNotifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, unread, order_status, approval_request
  int _unreadCount = 0;
  Set<String> _processingApprovals = {}; // Track which listings are being approved
  Set<String> _approvedListings = {}; // Track which listings have been approved

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _notificationService.getNotifications();
      
      if (result['success'] == true) {
        setState(() {
          _notifications = result['notifications'] as List<AppNotification>;
          _unreadCount = result['unreadCount'] ?? 0;
          _applyFilter();
          _isLoading = false;
        });
      } else {
        // Show error message
        setState(() {
          _notifications = [];
          _unreadCount = 0;
          _applyFilter();
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to load notifications'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
      setState(() {
        _notifications = [];
        _unreadCount = 0;
        _applyFilter();
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'all') {
        _filteredNotifications = _notifications;
      } else if (_selectedFilter == 'unread') {
        _filteredNotifications = _notifications.where((n) => !n.isRead).toList();
      } else {
        _filteredNotifications = _notifications.where((n) => n.type == _selectedFilter).toList();
      }
    });
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      await _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    final result = await _notificationService.markAllAsRead();
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      await _loadNotifications();
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.deleteNotification(notification.id);
      await _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    _markAsRead(notification);

    // Navigate based on notification type
    if (notification.type == 'order_status' || notification.type == 'approval_request') {
      if (widget.user?.isDonor == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingTrackerPage(user: widget.user!),
          ),
        );
      } else if (widget.user?.isReceiver == true) {
        if (notification.orderStatus == 'in_transit' || 
            notification.orderStatus == 'out_for_delivery') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveOrderTrackerPage(user: widget.user!),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderHistoryPage(user: widget.user!),
            ),
          );
        }
      }
    } else if (notification.type == 'listing_claimed') {
      if (widget.user?.isDonor == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingTrackerPage(user: widget.user!),
          ),
        );
      }
    }
  }

  Future<void> _approveOrder(AppNotification notification) async {
    if (notification.listingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to approve: Listing information missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Add to processing set
    setState(() {
      _processingApprovals.add(notification.listingId!);
    });

    try {
      final result = await _orderService.approveOrder(notification.listingId!);

      if (result['success'] == true) {
        // Add to approved set
        setState(() {
          _approvedListings.add(notification.listingId!);
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order approved successfully! 🎉'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Reload notifications to reflect the change
        await _loadNotifications();
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to approve order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Remove from processing set
      if (mounted) {
        setState(() {
          _processingApprovals.remove(notification.listingId!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEFDD),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFCEFDD),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE07A3E),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: const Color(0xFFFCEFDD),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _notifications.length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', 'unread', _unreadCount),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Order Status',
                    'order_status',
                    _notifications.where((n) => n.type == 'order_status').length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Approvals',
                    'approval_request',
                    _notifications.where((n) => n.type == 'approval_request').length,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Messages',
                    'message',
                    _notifications.where((n) => n.type == 'message').length,
                  ),
                ],
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE07A3E)),
                    ),
                  )
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: const Color(0xFFE07A3E),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: CommonFooter(
        selectedIndex: 0,
        user: widget.user,
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue, int count) {
    final isSelected = _selectedFilter == filterValue;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFFE07A3E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFFE07A3E) : Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filterValue;
          _applyFilter();
        });
      },
      selectedColor: const Color(0xFFE07A3E),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFFE07A3E) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFFFF9F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead 
                  ? Colors.grey.shade200 
                  : const Color(0xFFE07A3E).withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(notification.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      notification.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead 
                                    ? FontWeight.w600 
                                    : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE07A3E),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification.relativeTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          // Approve button for approval_request notifications
                          if (notification.type == 'approval_request' && 
                              widget.user?.isDonor == true &&
                              notification.listingId != null &&
                              !_approvedListings.contains(notification.listingId))
                            ElevatedButton.icon(
                              onPressed: _processingApprovals.contains(notification.listingId)
                                  ? null
                                  : () => _approveOrder(notification),
                              icon: _processingApprovals.contains(notification.listingId)
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle, size: 18),
                              label: Text(
                                _processingApprovals.contains(notification.listingId)
                                    ? 'Approving...'
                                    : 'Approve',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF20B2AA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          // Show "Approved" badge if already approved
                          if (notification.type == 'approval_request' && 
                              widget.user?.isDonor == true &&
                              notification.listingId != null &&
                              _approvedListings.contains(notification.listingId))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Approved',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'unread' 
                ? 'No unread notifications'
                : 'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'unread'
                ? 'You\'re all caught up!'
                : 'When you receive notifications, they\'ll appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
