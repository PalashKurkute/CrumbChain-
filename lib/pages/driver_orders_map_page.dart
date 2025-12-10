import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user.dart';
import '../models/listing.dart';
import '../services/order_service.dart';
import '../widgets/common_footer.dart';

class DriverOrdersMapPage extends StatefulWidget {
  final User user;

  const DriverOrdersMapPage({super.key, required this.user});

  @override
  State<DriverOrdersMapPage> createState() => _DriverOrdersMapPageState();
}

class OrderWithDistance {
  final Listing order;
  final LatLng coordinates;
  final double? distanceInKm;

  OrderWithDistance({
    required this.order,
    required this.coordinates,
    this.distanceInKm,
  });
}

class _DriverOrdersMapPageState extends State<DriverOrdersMapPage> {
  final OrderService _orderService = OrderService();
  final MapController _mapController = MapController();

  List<OrderWithDistance> _ordersWithDistance = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _errorMessage;
  LatLng _currentPosition = const LatLng(19.0760, 72.8777); // Mumbai default
  bool _locationPermissionGranted = false;
  OrderWithDistance? _selectedOrder;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _fetchOrders();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationPermissionGranted = false;
        });
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          _locationPermissionGranted = true;
        });

        // Get current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      print('❌ Error getting location: $e');
    }
  }

  Future<void> _fetchOrders() async {
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

        // Geocode orders and create markers
        await _processOrders(orders);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load orders';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processOrders(List<Listing> orders) async {
    List<Marker> markers = [];
    List<OrderWithDistance> processedOrders = [];

    for (var order in orders) {
      try {
        LatLng? coordinates;

        // Try to use existing coordinates if available
        if (order.latitude != null && order.longitude != null) {
          coordinates = LatLng(order.latitude!, order.longitude!);
        } else {
          // Geocode the location string
          coordinates = await _geocodeAddress(order.location);
        }

        if (coordinates != null) {
          // Calculate distance from driver's location
          double? distance;
          if (_locationPermissionGranted) {
            distance =
                Geolocator.distanceBetween(
                  _currentPosition.latitude,
                  _currentPosition.longitude,
                  coordinates.latitude,
                  coordinates.longitude,
                ) /
                1000; // Convert to kilometers
          }

          final orderWithDistance = OrderWithDistance(
            order: order,
            coordinates: coordinates,
            distanceInKm: distance,
          );

          processedOrders.add(orderWithDistance);

          markers.add(
            Marker(
              point: coordinates,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOrder = orderWithDistance;
                  });
                  if (coordinates != null) {
                    _mapController.move(coordinates, 15);
                  }
                  // Show popup with order details
                  _showOrderDetails(orderWithDistance);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    // Marker icon
                    Icon(
                      Icons.location_on,
                      color: _selectedOrder?.order.id == order.id
                          ? const Color(0xFF20B2AA)
                          : const Color(0xFFE07A3E),
                      size: 50,
                    ),
                    // Delivery icon overlay
                    const Positioned(
                      top: 8,
                      child: Icon(
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        print('❌ Error processing order ${order.id}: $e');
      }
    }

    // Sort by distance (closest first)
    processedOrders.sort((a, b) {
      if (a.distanceInKm == null && b.distanceInKm == null) return 0;
      if (a.distanceInKm == null) return 1;
      if (b.distanceInKm == null) return -1;
      return a.distanceInKm!.compareTo(b.distanceInKm!);
    });

    setState(() {
      _ordersWithDistance = processedOrders;
      _markers = markers;
    });
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print('❌ Geocoding error for $address: $e');
    }
    return null;
  }

  Widget _buildOrderCard(OrderWithDistance orderWithDistance) {
    final order = orderWithDistance.order;
    final distance = orderWithDistance.distanceInKm;
    final isSelected = _selectedOrder?.order.id == order.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOrder = orderWithDistance;
        });
        _mapController.move(orderWithDistance.coordinates, 15);
      },
      child: Container(
        width: 280,
        height: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF20B2AA) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.15 : 0.08),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with food type and distance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF20B2AA)
                    : const Color(0xFFE07A3E),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      order.foodType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (distance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me,
                            size: 12,
                            color: Color(0xFFE07A3E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance < 1
                                ? '${(distance * 1000).toInt()}m'
                                : '${distance.toStringAsFixed(1)}km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE07A3E),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Content - Pickup and delivery info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                    // Pickup location
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          size: 14,
                          color: Color(0xFFE07A3E),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pickup: ${order.userName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Delivery to
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 14,
                          color: Color(0xFF20B2AA),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Deliver: ${order.claimedByName ?? "Receiver"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Quantity and location
                    Row(
                      children: [
                        Icon(Icons.fastfood, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          order.quantity,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.location,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  void _showOrderDetails(OrderWithDistance orderWithDistance) {
    final order = orderWithDistance.order;
    final distance = orderWithDistance.distanceInKm;

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

                  // Food Type (Title)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.foodType,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE07A3E),
                          ),
                        ),
                      ),
                      if (distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEEDD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE07A3E)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me,
                                size: 16,
                                color: Color(0xFFE07A3E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                distance < 1
                                    ? '${(distance * 1000).toInt()}m away'
                                    : '${distance.toStringAsFixed(1)}km away',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE07A3E),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

                  // Pickup Details
                  _buildSectionHeader('Pickup Details', Icons.restaurant),
                  _buildDetailRow('Donor', order.userName),
                  _buildDetailRow('Location', order.location),
                  if (order.pickupTime != null)
                    _buildDetailRow('Time', order.pickupTime!),
                  const SizedBox(height: 16),

                  // Delivery Details
                  _buildSectionHeader('Delivery Details', Icons.person),
                  _buildDetailRow('Receiver', order.claimedByName ?? 'N/A'),
                  const SizedBox(height: 16),

                  // Food Details
                  _buildSectionHeader('Food Details', Icons.fastfood),
                  _buildDetailRow('Quantity', order.quantity),
                  _buildDetailRow('Dietary Tag', order.dietaryTag),
                  _buildDetailRow('Temperature', order.temperatureStatus),
                  _buildDetailRow('Packaging', order.packagingType),

                  if (order.isPaidDonation) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEEDD),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE07A3E)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Color(0xFFE07A3E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Paid Donation: ₹${order.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE07A3E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _claimDelivery(order);
                          },
                          icon: const Icon(Icons.local_shipping, size: 22),
                          label: const Text(
                            'Claim Delivery',
                            style: TextStyle(fontSize: 16),
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
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // TODO: Implement directions functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Opening directions...'),
                                backgroundColor: Color(0xFFE07A3E),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions, size: 20),
                          label: const Text('Navigate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE07A3E),
                            side: const BorderSide(
                              color: Color(0xFFE07A3E),
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _claimDelivery(Listing order) async {
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
        const SnackBar(
          content: Text('Delivery claimed successfully! 🚗'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchOrders(); // Refresh map
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to claim delivery'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_currentPosition, 15);
            },
            tooltip: 'Go to my location',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchOrders,
            tooltip: 'Refresh orders',
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
                    onPressed: _fetchOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20B2AA),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Map Section
                Expanded(
                  child: Stack(
                    children: [
                      // Map
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentPosition,
                          initialZoom: 12,
                          minZoom: 5,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.crumbchain',
                          ),
                          MarkerLayer(markers: _markers),
                          // Current location marker
                          if (_locationPermissionGranted)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentPosition,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Orders count badge
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_shipping,
                                color: Color(0xFF20B2AA),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_ordersWithDistance.length} available',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF20B2AA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal Scrollable List of Orders
                if (_ordersWithDistance.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Row(
                            children: [
                              const Text(
                                'Nearby Deliveries',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF20B2AA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_ordersWithDistance.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.swipe,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Swipe',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _ordersWithDistance.length,
                            itemBuilder: (context, index) {
                              return _buildOrderCard(
                                _ordersWithDistance[index],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: CommonFooter(selectedIndex: 1, user: widget.user),
    );
  }
}
