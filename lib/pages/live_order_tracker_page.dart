import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/common_footer.dart';
import '../models/user.dart';
import '../services/order_service.dart';
import '../services/rating_service.dart';

/// Live Order Tracker for Receivers - Real-time tracking with backend data
class LiveOrderTrackerPage extends StatefulWidget {
  final User? user;

  const LiveOrderTrackerPage({super.key, this.user});

  @override
  State<LiveOrderTrackerPage> createState() => _LiveOrderTrackerPageState();
}

class _LiveOrderTrackerPageState extends State<LiveOrderTrackerPage> {
  final OrderService _orderService = OrderService();
  final RatingService _ratingService = RatingService();
  List<dynamic> _activeOrders = [];
  List<dynamic> _recentOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadActiveOrders();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveOrders() async {
    try {
      final response = await _orderService.getActiveOrders();
      
      if (response['success']) {
        if (mounted) {
          setState(() {
            _activeOrders = response['data']['activeOrders'] ?? [];
            _isLoading = false;
            _errorMessage = null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'];
            _isLoading = false;
          });
        }
      }
      
      // Also load recent completed orders
      await _loadRecentOrders();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load orders: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String listingId, String currentStatus, [Map<String, dynamic>? orderData]) async {
    // Determine next status based on current status
    String nextStatus;
    String statusMessage;
    
    switch (currentStatus) {
      case 'approved':
        nextStatus = 'in_transit';
        statusMessage = 'Marking order as In Transit...';
        break;
      case 'in_transit':
        nextStatus = 'out_for_delivery';
        statusMessage = 'Marking order as Out for Delivery...';
        break;
      case 'out_for_delivery':
        nextStatus = 'delivered';
        statusMessage = 'Marking order as Delivered...';
        break;
      case 'delivered':
        nextStatus = 'completed';
        statusMessage = 'Completing the order...';
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot update status from current state'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
    }

    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMessage),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF20B2AA),
      ),
    );

    try {
      final result = await _orderService.updateOrderStatus(listingId, nextStatus);

      if (result['success']) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order status updated to $nextStatus'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Reload orders to reflect changes
        await _loadActiveOrders();

        // If completed, show rating dialog
        if (nextStatus == 'completed' && mounted && orderData != null) {
          _showRatingDialog(orderData);
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update status'),
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
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final response = await _orderService.getMyOrders();
      
      if (response['success']) {
        final receivedOrders = response['data']['receivedOrders'] ?? [];
        final completed = receivedOrders.where((order) {
          final status = order['orderStatus'];
          return status == 'delivered' || status == 'completed';
        }).take(5).toList();
        
        if (mounted) {
          setState(() {
            _recentOrders = completed;
          });
        }
      }
    } catch (e) {
      // Silently fail for recent orders
      print('Error loading recent orders: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF20B2AA)),
            onPressed: _isLoading ? null : _loadActiveOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: const Color(0xFF20B2AA),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF20B2AA)),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadActiveOrders,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF20B2AA),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Top section with logo
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.volunteer_activism,
                                size: 80,
                                color: Color(0xFFE07A3E),
                              );
                            },
                          ),
                        ),

                        // Cream background section with icon and description
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFFCEEDD),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          child: Column(
                            children: [
                              // Feature icon
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/images/live-tracker.png',
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.local_shipping,
                                      size: 40,
                                      color: Colors.black87,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                'Live Order Tracker',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Track your active deliveries in real-time',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Active Orders Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF20B2AA),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Active Deliveries',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF20B2AA).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_activeOrders.length} Active',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF20B2AA),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Body Content - Active Orders
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _activeOrders.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.inbox_outlined,
                                            size: 64, color: Colors.grey.shade300),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No active deliveries',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Claim listings to start tracking',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _activeOrders.map((order) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildCompactOrderCard(order),
                                    );
                                  }).toList(),
                                ),
                        ),

                        if (_recentOrders.isNotEmpty) ...[
                          const SizedBox(height: 24),

                          // Recent Deliveries Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Recent Deliveries',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Recent Completed Orders
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: _recentOrders.map((order) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildRecentDeliveryCard(order),
                                );
                              }).toList(),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
      bottomNavigationBar: CommonFooter(user: widget.user),
    );
  }

  Widget _buildCompactOrderCard(dynamic order) {
    final String orderId = order['_id']?.substring(0, 8).toUpperCase() ?? 'ORDER';
    final String foodName = order['mealType'] ?? 'Food Item';
    final String donor = order['userName'] ?? 'Anonymous Donor';
    final String quantity = order['quantity'] ?? 'N/A';
    final String status = order['orderStatus'] ?? 'approved';
    
    final Color statusColor = Color(OrderService.getStatusColor(status));
    
    IconData statusIcon;
    switch (status) {
      case 'approved':
        statusIcon = Icons.check_circle_outline;
        break;
      case 'in_transit':
        statusIcon = Icons.local_shipping;
        break;
      case 'out_for_delivery':
        statusIcon = Icons.delivery_dining;
        break;
      default:
        statusIcon = Icons.info;
    }
    
    // Calculate progress based on status
    double progress;
    switch (status) {
      case 'approved':
        progress = 0.25;
        break;
      case 'in_transit':
        progress = 0.6;
        break;
      case 'out_for_delivery':
        progress = 0.85;
        break;
      default:
        progress = 0.1;
    }
    
    // Calculate ETA (simplified)
    String eta;
    switch (status) {
      case 'out_for_delivery':
        eta = '10-15 mins';
        break;
      case 'in_transit':
        eta = '20-30 mins';
        break;
      case 'approved':
        eta = '45-60 mins';
        break;
      default:
        eta = 'TBD';
    }
    
    // Simulated picker info (in production, this would come from backend)
    String? pickerName;
    String? pickerVehicle;
    double? pickerRating;
    
    if (status == 'in_transit' || status == 'out_for_delivery') {
      pickerName = 'Delivery Partner';
      pickerVehicle = 'Vehicle';
      pickerRating = 4.5;
    }

    return GestureDetector(
      onTap: () => _showOrderDetails(order),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEEDD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                // Status Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Order Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            foodName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              orderId,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.store,
                              size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            donor,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            ' • $quantity',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // ETA Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        eta,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),

            // Picker Info (if assigned)
            if (pickerName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF20B2AA),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickerName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (pickerVehicle != null)
                            Text(
                              pickerVehicle,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (pickerRating != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE07A3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFE07A3E),
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              pickerRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () {
                        if (pickerName != null) {
                          _callPicker(pickerName);
                        }
                      },
                      icon: const Icon(
                        Icons.phone,
                        color: Color(0xFF20B2AA),
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 14,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Finding delivery partner...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Status Update Button (Simulation)
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _updateOrderStatus(order['_id'], status, order),
                icon: Icon(_getNextStatusIcon(status), size: 18),
                label: Text(_getNextStatusButtonText(status)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDeliveryCard(dynamic order) {
    final String foodName = order['mealType'] ?? 'Food Item';
    final String donor = order['userName'] ?? 'Anonymous Donor';
    final String quantity = order['quantity'] ?? 'N/A';
    final String deliveredTime = _formatTimeAgo(order['deliveredAt'] ?? order['completedAt']);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  foodName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.store, size: 11, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$donor • $quantity',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF20B2AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people,
                      size: 11,
                      color: Color(0xFF20B2AA),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${order['crowdSize'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF20B2AA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                deliveredTime,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshOrders() async {
    await _loadActiveOrders();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Orders updated'),
          backgroundColor: Color(0xFF20B2AA),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showOrderDetails(dynamic order) {
    final String orderId = order['_id']?.substring(0, 8).toUpperCase() ?? 'ORDER';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: $orderId',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Detailed tracking information would be displayed here including:',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailItem('📍 Live location map'),
                    _buildDetailItem('📞 Contact picker/donor'),
                    _buildDetailItem('📦 Complete order details'),
                    _buildDetailItem('🕐 Estimated delivery time'),
                    _buildDetailItem('📝 Special instructions'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening live map view...'),
                              backgroundColor: Color(0xFF20B2AA),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF20B2AA),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View on Map',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF20B2AA),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  void _callPicker(String pickerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $pickerName...'),
        backgroundColor: const Color(0xFF20B2AA),
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  IconData _getNextStatusIcon(String currentStatus) {
    switch (currentStatus) {
      case 'approved':
        return Icons.local_shipping;
      case 'in_transit':
        return Icons.delivery_dining;
      case 'out_for_delivery':
        return Icons.check_circle;
      case 'delivered':
        return Icons.done_all;
      default:
        return Icons.arrow_forward;
    }
  }

  String _getNextStatusButtonText(String currentStatus) {
    switch (currentStatus) {
      case 'approved':
        return 'Mark as In Transit';
      case 'in_transit':
        return 'Mark as Out for Delivery';
      case 'out_for_delivery':
        return 'Mark as Delivered';
      case 'delivered':
        return 'Complete Order';
      default:
        return 'Update Status';
    }
  }

  String _formatTimeAgo(dynamic dateValue) {
    if (dateValue == null) return 'Recently';
    
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return 'Over a week ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showRatingDialog(Map<String, dynamic> order) {
    double rating = 5.0;
    final TextEditingController reviewController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Rate Your Experience'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your experience with ${order['userName'] ?? 'the donor'}?',
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Rating:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              rating = (index + 1).toDouble();
                            });
                          },
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Review (Optional):',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    // Show completion message without rating
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order completed! You can rate later from notifications.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    
                    // Submit rating
                    final result = await _ratingService.submitRating(
                      listingId: order['_id'],
                      donorId: order['userId'],
                      rating: rating,
                      review: reviewController.text,
                    );
                    
                    if (mounted) {
                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Thank you for your ${rating.toInt()}-star rating! 🎉'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Failed to submit rating'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20B2AA),
                  ),
                  child: const Text('Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
