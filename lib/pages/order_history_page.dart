import 'package:flutter/material.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';

class OrderHistoryPage extends StatefulWidget {
  final User? user;

  const OrderHistoryPage({super.key, this.user});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      ),
      body: Column(
        children: [
          // Top section with logo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.volunteer_activism,
                  size: 100,
                  color: Color(0xFFE07A3E),
                );
              },
            ),
          ),

          // Cream background section with icon and description
          Container(
            width: double.infinity,
            color: const Color(0xFFFCEEDD),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                // Feature icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/order-history.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.black87,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Order History',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Track all your food orders, requirements, and deliveries',
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

          const SizedBox(height: 16),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCEEDD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              indicator: BoxDecoration(
                color: const Color(0xFF20B2AA),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Accepted'),
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAcceptedTab(),
                _buildPendingTab(),
                _buildCompletedTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CommonFooter(user: widget.user),
    );
  }

  // Accepted Requirements Tab
  Widget _buildAcceptedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildAcceptedCard(
            donorName: 'Restaurant ABC',
            itemName: 'Mixed Vegetables',
            quantity: '15 kg',
            acceptedDate: 'Jan 20, 2025',
            estimatedDelivery: 'Jan 21, 2025',
            status: 'Preparing',
          ),
          const SizedBox(height: 12),
          _buildAcceptedCard(
            donorName: 'Hotel Grand',
            itemName: 'Rice & Dal',
            quantity: '20 kg',
            acceptedDate: 'Jan 19, 2025',
            estimatedDelivery: 'Jan 20, 2025',
            status: 'Ready for Pickup',
          ),
          const SizedBox(height: 12),
          _buildAcceptedCard(
            donorName: 'Bakery Fresh',
            itemName: 'Bread & Pastries',
            quantity: '50 items',
            acceptedDate: 'Jan 18, 2025',
            estimatedDelivery: 'Jan 19, 2025',
            status: 'In Transit',
          ),
        ],
      ),
    );
  }

  // Pending Orders Tab
  Widget _buildPendingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildPendingCard(
            itemName: 'Fruits & Vegetables',
            requestedDate: 'Jan 22, 2025',
            quantity: '30 kg',
            urgency: 'High',
          ),
          const SizedBox(height: 12),
          _buildPendingCard(
            itemName: 'Dry Groceries',
            requestedDate: 'Jan 21, 2025',
            quantity: '25 kg',
            urgency: 'Medium',
          ),
          const SizedBox(height: 12),
          _buildPendingCard(
            itemName: 'Cooked Meals',
            requestedDate: 'Jan 20, 2025',
            quantity: '40 servings',
            urgency: 'Low',
          ),
        ],
      ),
    );
  }

  // Completed Orders Tab
  Widget _buildCompletedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildCompletedCard(
            donorName: 'Cafe Delight',
            itemName: 'Sandwiches & Snacks',
            quantity: '40 items',
            deliveredDate: 'Jan 15, 2025',
            beneficiaries: 35,
            rating: 4.8,
          ),
          const SizedBox(height: 12),
          _buildCompletedCard(
            donorName: 'Restaurant XYZ',
            itemName: 'Biryani',
            quantity: '25 kg',
            deliveredDate: 'Jan 12, 2025',
            beneficiaries: 50,
            rating: 4.9,
          ),
          const SizedBox(height: 12),
          _buildCompletedCard(
            donorName: 'Grocery Mart',
            itemName: 'Fresh Produce',
            quantity: '35 kg',
            deliveredDate: 'Jan 10, 2025',
            beneficiaries: 45,
            rating: 4.7,
          ),
          const SizedBox(height: 12),
          _buildCompletedCard(
            donorName: 'Hotel Paradise',
            itemName: 'Dal & Chapati',
            quantity: '30 kg',
            deliveredDate: 'Jan 5, 2025',
            beneficiaries: 60,
            rating: 4.6,
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedCard({
    required String donorName,
    required String itemName,
    required String quantity,
    required String acceptedDate,
    required String estimatedDelivery,
    required String status,
  }) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'Preparing':
        statusColor = Colors.orange;
        statusIcon = Icons.restaurant;
        break;
      case 'Ready for Pickup':
        statusColor = const Color(0xFF20B2AA);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'In Transit':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEDD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 14, color: Color(0xFF20B2AA)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donorName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF20B2AA),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                quantity,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Accepted: $acceptedDate',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_shipping, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Est. Delivery: $estimatedDelivery',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard({
    required String itemName,
    required String requestedDate,
    required String quantity,
    required String urgency,
  }) {
    Color urgencyColor;
    switch (urgency) {
      case 'High':
        urgencyColor = Colors.red;
        break;
      case 'Medium':
        urgencyColor = Colors.orange;
        break;
      case 'Low':
        urgencyColor = Colors.green;
        break;
      default:
        urgencyColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEDD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: urgencyColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.priority_high, size: 14, color: urgencyColor),
                    const SizedBox(width: 4),
                    Text(
                      urgency,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: urgencyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                quantity,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Requested: $requestedDate',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.pending_actions,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                'Waiting for donor acceptance',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedCard({
    required String donorName,
    required String itemName,
    required String quantity,
    required String deliveredDate,
    required int beneficiaries,
    required double rating,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEDD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person,
                            size: 14, color: Color(0xFF20B2AA)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            donorName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF20B2AA),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                quantity,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Delivered: $deliveredDate',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Beneficiaries badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF20B2AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF20B2AA)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people,
                        size: 16, color: Color(0xFF20B2AA)),
                    const SizedBox(width: 4),
                    Text(
                      '$beneficiaries served',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF20B2AA),
                      ),
                    ),
                  ],
                ),
              ),
              // Rating badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE07A3E)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFE07A3E)),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE07A3E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
