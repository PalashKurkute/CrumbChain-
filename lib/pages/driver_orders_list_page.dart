import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/listing.dart';
import '../services/order_service.dart';
import '../widgets/common_footer.dart';

class DriverOrdersListPage extends StatefulWidget {
  final User user;

  const DriverOrdersListPage({super.key, required this.user});

  @override
  State<DriverOrdersListPage> createState() => _DriverOrdersListPageState();
}

class _DriverOrdersListPageState extends State<DriverOrdersListPage> {
  final OrderService _orderService = OrderService();
  List<Listing> _availableOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAvailableOrders();
  }

  Future<void> _fetchAvailableOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _orderService.getAvailableOrdersForDrivers();

      if (result['success']) {
        final ordersData = result['data']['orders'] as List;
        final orders = ordersData
            .map((json) => Listing.fromJson(json))
            .toList();

        setState(() {
          _availableOrders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load orders';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _claimDelivery(Listing order) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Claim Delivery?'),
        content: Text(
          'Do you want to claim the delivery for "${order.foodType}"?\n\n'
          'Pickup: ${order.location}\n'
          'Deliver to: ${order.claimedByName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20B2AA),
            ),
            child: const Text('Claim Delivery'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF20B2AA)),
      ),
    );

    final result = await _orderService.claimDelivery(order.id);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Delivery claimed successfully! 🚗'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to active deliveries
            },
          ),
        ),
      );
      _fetchAvailableOrders(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to claim delivery'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrderCard(Listing order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Food type and status badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.foodType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE07A3E),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Approved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pickup location
              Row(
                children: [
                  const Icon(
                    Icons.restaurant,
                    size: 18,
                    color: Color(0xFFE07A3E),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pickup:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.userName} - ${order.location}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Delivery to (receiver)
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Color(0xFF20B2AA)),
                  const SizedBox(width: 8),
                  const Text(
                    'Deliver to:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.claimedByName ?? 'Receiver',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details row
              Row(
                children: [
                  _buildDetailChip(Icons.restaurant_menu, order.quantity),
                  const SizedBox(width: 8),
                  _buildDetailChip(Icons.local_dining, order.dietaryTag),
                  const SizedBox(width: 8),
                  _buildDetailChip(Icons.thermostat, order.temperatureStatus),
                ],
              ),
              const SizedBox(height: 16),

              // Claim button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _claimDelivery(order),
                  icon: const Icon(Icons.local_shipping, size: 20),
                  label: const Text(
                    'Claim Delivery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20B2AA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(Listing order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    order.foodType,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE07A3E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (order.description.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pickup details
                  _buildSectionHeader('Pickup Details', Icons.restaurant),
                  _buildDetailRow('Donor', order.userName),
                  _buildDetailRow('Location', order.location),
                  if (order.pickupTime != null)
                    _buildDetailRow('Pickup Time', order.pickupTime!),
                  const SizedBox(height: 16),

                  // Delivery details
                  _buildSectionHeader('Delivery Details', Icons.person),
                  _buildDetailRow('Receiver', order.claimedByName ?? 'N/A'),
                  const SizedBox(height: 16),

                  // Food details
                  _buildSectionHeader('Food Details', Icons.restaurant_menu),
                  _buildDetailRow('Quantity', order.quantity),
                  _buildDetailRow('Dietary Tag', order.dietaryTag),
                  _buildDetailRow('Temperature', order.temperatureStatus),
                  _buildDetailRow('Packaging', order.packagingType),
                  if (order.datePrepared != null)
                    _buildDetailRow('Prepared On', order.datePrepared!),

                  const SizedBox(height: 24),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _claimDelivery(order);
                      },
                      icon: const Icon(Icons.local_shipping, size: 22),
                      label: const Text(
                        'Claim This Delivery',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20B2AA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFE07A3E)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE07A3E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Available Deliveries',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAvailableOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF20B2AA)),
                  SizedBox(height: 16),
                  Text('Loading available deliveries...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchAvailableOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20B2AA),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _availableOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Deliveries Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new delivery opportunities',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _fetchAvailableOrders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20B2AA),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Header with count
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFFCEEDD),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Color(0xFFE07A3E),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_availableOrders.length} ${_availableOrders.length == 1 ? "Delivery" : "Deliveries"} Available',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE07A3E),
                        ),
                      ),
                    ],
                  ),
                ),

                // List of orders
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchAvailableOrders,
                    color: const Color(0xFF20B2AA),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: _availableOrders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(_availableOrders[index]);
                      },
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: CommonFooter(selectedIndex: 1, user: widget.user),
    );
  }
}
