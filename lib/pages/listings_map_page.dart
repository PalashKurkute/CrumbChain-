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

class ListingWithDistance {
  final Listing listing;
  final LatLng coordinates;
  final double? distanceInKm;

  ListingWithDistance({
    required this.listing,
    required this.coordinates,
    this.distanceInKm,
  });
}

class _ListingsMapPageState extends State<ListingsMapPage> {
  final ListingService _listingService = ListingService();
  final MapController _mapController = MapController();
  
  List<ListingWithDistance> _listingsWithDistance = [];
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _errorMessage;
  LatLng _currentPosition = const LatLng(19.0760, 72.8777); // Mumbai default
  bool _locationPermissionGranted = false;
  ListingWithDistance? _selectedListing;

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
    List<ListingWithDistance> processedListings = [];

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
          // Calculate distance from user's location
          double? distance;
          if (_locationPermissionGranted) {
            distance = Geolocator.distanceBetween(
              _currentPosition.latitude,
              _currentPosition.longitude,
              coordinates.latitude,
              coordinates.longitude,
            ) / 1000; // Convert to kilometers
          }

          final listingWithDistance = ListingWithDistance(
            listing: listing,
            coordinates: coordinates,
            distanceInKm: distance,
          );

          processedListings.add(listingWithDistance);
          
          markers.add(
            Marker(
              point: coordinates,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedListing = listingWithDistance;
                  });
                  if (coordinates != null) {
                    _mapController.move(coordinates, 15);
                  }
                  // Show popup with listing details
                  _showListingDetails(listingWithDistance);
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
                      color: _selectedListing?.listing.id == listing.id
                          ? const Color(0xFF20B2AA)
                          : const Color(0xFFE07A3E),
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

    // Sort by distance (closest first)
    processedListings.sort((a, b) {
      if (a.distanceInKm == null && b.distanceInKm == null) return 0;
      if (a.distanceInKm == null) return 1;
      if (b.distanceInKm == null) return -1;
      return a.distanceInKm!.compareTo(b.distanceInKm!);
    });

    setState(() {
      _listingsWithDistance = processedListings;
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

  Widget _buildListingCard(ListingWithDistance listingWithDistance) {
    final listing = listingWithDistance.listing;
    final distance = listingWithDistance.distanceInKm;
    final isSelected = _selectedListing?.listing.id == listing.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedListing = listingWithDistance;
        });
        _mapController.move(listingWithDistance.coordinates, 15);
      },
      child: Container(
        width: 280,
        height: 160, // Reduced height for simpler card
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF20B2AA) : const Color(0xFFE07A3E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      listing.foodType,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 12, color: Color(0xFFE07A3E)),
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

            // Content - Only description and donor name
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Expanded(
                      child: Text(
                        listing.description.isNotEmpty 
                            ? listing.description 
                            : 'Fresh food available for pickup',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 10),

                    // Posted by
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Posted by ${listing.userName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
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
            ),
          ],
        ),
      ),
    );
  }

  void _showListingDetails(ListingWithDistance listingWithDistance) {
    final listing = listingWithDistance.listing;
    final distance = listingWithDistance.distanceInKm;
    
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
                          listing.foodType,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE07A3E),
                          ),
                        ),
                      ),
                      if (distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEEDD),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE07A3E)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.near_me, size: 16, color: Color(0xFFE07A3E)),
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
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement claim functionality
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Claiming "${listing.foodType}"...'),
                                backgroundColor: const Color(0xFF20B2AA),
                                action: SnackBarAction(
                                  label: 'OK',
                                  textColor: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 22),
                          label: const Text('Claim Listing', style: TextStyle(fontSize: 16)),
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
                            // TODO: Implement directions functionality
                            Navigator.pop(context);
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
                            side: const BorderSide(color: Color(0xFFE07A3E), width: 2),
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

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDietaryIcon(String dietaryTag) {
    switch (dietaryTag.toLowerCase()) {
      case 'vegetarian':
      case 'veg':
        return Icons.eco;
      case 'non-vegetarian':
      case 'non-veg':
        return Icons.set_meal;
      case 'vegan':
        return Icons.spa;
      default:
        return Icons.restaurant;
    }
  }

  IconData _getTemperatureIcon(String temperature) {
    switch (temperature.toLowerCase()) {
      case 'hot':
        return Icons.local_fire_department;
      case 'cold':
        return Icons.ac_unit;
      default:
        return Icons.thermostat;
    }
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
                                    '${_listingsWithDistance.length} available',
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
                    ),

                    // Horizontal Scrollable List of Listings
                    if (_listingsWithDistance.isNotEmpty)
                      Container(
                        height: 180, // Reduced height for simpler cards
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
                                    'Nearby Listings',
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
                                      color: const Color(0xFFE07A3E),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_listingsWithDistance.length}',
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
                                itemCount: _listingsWithDistance.length,
                                itemBuilder: (context, index) {
                                  return _buildListingCard(_listingsWithDistance[index]);
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
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
