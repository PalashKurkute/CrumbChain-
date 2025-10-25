import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import '../widgets/common_footer.dart';

class ListingsMapPage extends StatefulWidget {
  final User user;

  const ListingsMapPage({super.key, required this.user});

  @override
  State<ListingsMapPage> createState() => _ListingsMapPageState();
}

class _ListingsMapPageState extends State<ListingsMapPage> {
  final ListingService _listingService = ListingService();
  final MapController _mapController = MapController();
  
  List<Listing> _listings = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _errorMessage;
  LatLng _currentPosition = const LatLng(19.0760, 72.8777); // Mumbai default
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _fetchListings();
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

  Future<void> _fetchListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _listingService.getListings(
        userOnly: false,
        status: 'active',
      );

      if (result['success']) {
        final listingsData = result['data']['listings'] as List;
        final listings = listingsData.map((json) => Listing.fromJson(json)).toList();

        // Geocode listings and create markers
        await _processListings(listings);
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load listings';
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

  Future<void> _processListings(List<Listing> listings) async {
    List<Marker> markers = [];
    List<Listing> processedListings = [];

    for (var listing in listings) {
      try {
        LatLng? coordinates;

        // Try to use existing coordinates if available
        if (listing.latitude != null && listing.longitude != null) {
          coordinates = LatLng(listing.latitude!, listing.longitude!);
        } else {
          // Geocode the location string
          coordinates = await _geocodeAddress(listing.location);
        }

        if (coordinates != null) {
          processedListings.add(listing);
          markers.add(
            Marker(
              point: coordinates,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showListingDetails(listing),
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
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFE07A3E),
                      size: 50,
                    ),
                    // Food icon overlay
                    const Positioned(
                      top: 8,
                      child: Icon(
                        Icons.restaurant,
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
        print('❌ Error processing listing ${listing.id}: $e');
      }
    }

    setState(() {
      _listings = processedListings;
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

  void _showListingDetails(Listing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                  Text(
                    listing.foodType,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE07A3E),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Donor name
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'By ${listing.userName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (listing.description.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Details grid
                  _buildDetailRow('Quantity', listing.quantity),
                  _buildDetailRow('Dietary Tag', listing.dietaryTag),
                  _buildDetailRow('Temperature', listing.temperatureStatus),
                  _buildDetailRow('Packaging', listing.packagingType),
                  _buildDetailRow('Location', listing.location),
                  
                  if (listing.pickupTime != null)
                    _buildDetailRow('Pickup Time', listing.pickupTime!),
                  
                  if (listing.datePrepared != null)
                    _buildDetailRow('Prepared On', listing.datePrepared!),

                  if (listing.isPaidDonation) ...[
                    const SizedBox(height: 8),
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
                            'Paid Donation: ₹${listing.amount.toStringAsFixed(2)}',
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
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement claim functionality
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Claim feature coming soon!'),
                                backgroundColor: Color(0xFFE07A3E),
                              ),
                            );
                          },
                          icon: const Icon(Icons.volunteer_activism),
                          label: const Text('Claim Food'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE07A3E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement directions functionality
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Directions feature coming soon!'),
                              backgroundColor: Color(0xFF20B2AA),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF20B2AA),
                          side: const BorderSide(color: Color(0xFF20B2AA)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
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
          'Available Listings',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
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
            onPressed: _fetchListings,
            tooltip: 'Refresh listings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFFE07A3E),
                  ),
                  SizedBox(height: 16),
                  Text('Loading listings...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchListings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE07A3E),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
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

                    // Listings count badge
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
                              Icons.restaurant,
                              color: Color(0xFFE07A3E),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_listings.length} available',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE07A3E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: CommonFooter(
        selectedIndex: 1,
        user: widget.user,
      ),
    );
  }
}
