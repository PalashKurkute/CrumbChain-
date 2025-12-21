import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';

class NearbyPage extends StatefulWidget {
  final User? user;

  const NearbyPage({super.key, this.user});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(19.0760, 72.8777); // Default: Mumbai
  bool _isLoadingLocation = false;
  String? _locationError;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  // Sample markers for hotels, NGOs, and food banks
  final List<Marker> _markers = [];

  // List of locations for the side panel
  final List<LocationData> _locations = [];

  // Selected location
  LocationData? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _initializeMarkers();
    // Check permission status first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionStatus();
      // Force map to render after build
      if (mounted) {
        setState(() {
          // Trigger rebuild to ensure map tiles load
        });
      }
    });
  }

  Future<void> _checkPermissionStatus() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      print('📍 Current permission status: $permission');

      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
          _hasPermission =
              (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse);
        });

        print('📍 Has permission: $_hasPermission');

        // If already has permission, get location immediately
        if (_hasPermission) {
          print('📍 Permission already granted, fetching location...');
          _getCurrentLocation();
        } else {
          print('📍 No permission, showing permission request screen');
        }
      }
    } catch (e) {
      print('❌ Error checking permission: $e');
      if (mounted) {
        setState(() {
          _isCheckingPermission = false;
          _hasPermission = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'Location services are disabled';
            _isLoadingLocation = false;
          });
          _showLocationServiceDialog();
        }
        return;
      }

      // Request permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationError = 'Location permission denied';
            _isLoadingLocation = false;
            _hasPermission = false;
          });
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = 'Permission permanently denied';
            _isLoadingLocation = false;
            _hasPermission = false;
          });
          _showOpenSettingsDialog();
        }
        return;
      }

      // Permission granted
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _locationError = null;
        });
        await _getCurrentLocation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Error requesting permission: ${e.toString()}';
          _isLoadingLocation = false;
          _hasPermission = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      print('📍 Fetching current location...');

      // Try to get last known position first (faster)
      Position? lastPosition;
      try {
        lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print(
            '📍 Using last known position: ${lastPosition.latitude}, ${lastPosition.longitude}',
          );
        }
      } catch (e) {
        print('📍 No last known position available');
      }

      // Get current position with increased timeout and medium accuracy as fallback
      Position position;

      try {
        position =
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 15),
              ),
            ).timeout(
              const Duration(seconds: 20),
              onTimeout: () async {
                print('⚠️ High accuracy timed out, trying medium accuracy...');
                // Fallback to medium accuracy
                return await Geolocator.getCurrentPosition(
                  locationSettings: const LocationSettings(
                    accuracy: LocationAccuracy.medium,
                    timeLimit: Duration(seconds: 10),
                  ),
                );
              },
            );
      } catch (e) {
        print('⚠️ Current position failed: $e');
        // Use last known position as fallback
        if (lastPosition != null) {
          print('📍 Using last known position as fallback');
          position = lastPosition;
        } else {
          rethrow;
        }
      }

      print(
        '📍 Location received: ${position.latitude}, ${position.longitude}',
      );
      print('📍 Accuracy: ${position.accuracy} meters');
      print('📍 Timestamp: ${position.timestamp}');

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
          _locationError = null;
        });

        // Move map to current position
        _mapController.move(_currentPosition, 14.0);

        print(
          '📍 Map centered to: ${_currentPosition.latitude}, ${_currentPosition.longitude}',
        );
      }
    } on TimeoutException catch (e) {
      print('❌ Location timeout: $e');
      if (mounted) {
        setState(() {
          _locationError =
              'Location request timed out. Please ensure GPS is enabled and try again.';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      print('❌ Error getting location: $e');

      // Check if it's a location service error
      if (e.toString().contains('location') &&
          e.toString().toLowerCase().contains('disabled')) {
        if (mounted) {
          setState(() {
            _locationError =
                'Location services are disabled. Please enable GPS in your device settings.';
            _isLoadingLocation = false;
          });
          _showLocationServiceDialog();
        }
      } else {
        if (mounted) {
          setState(() {
            _locationError = 'Failed to get location: ${e.toString()}';
            _isLoadingLocation = false;
          });
        }
      }
    }
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE07A3E), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services in your device settings to see nearby locations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _initializeLocations() {
    _locations.addAll([
      LocationData(
        id: 'org_001',
        name: 'Feeding India',
        description: 'Active food distribution center serving 500+ meals daily',
        type: 'NGO',
        position: const LatLng(19.0896, 72.8656),
        icon: Icons.volunteer_activism,
        color: Colors.green,
        address: 'Andheri West, Mumbai',
        timing: '9 AM - 8 PM',
        availableFood: ['Rice', 'Dal', 'Vegetables', 'Roti', 'Fruits'],
        contact: '+91 98765 43210',
      ),
      LocationData(
        id: 'org_002',
        name: 'Taj Hotel',
        description: 'Donates excess food daily to nearby shelters',
        type: 'Hotel',
        position: const LatLng(19.0760, 72.8777),
        icon: Icons.hotel,
        color: Colors.orange,
        address: 'Colaba, Mumbai',
        timing: 'Daily pickups at 10 PM',
        availableFood: ['Cooked Meals', 'Desserts', 'Bread', 'Pastries'],
        contact: '+91 98765 43211',
      ),
      LocationData(
        id: 'org_003',
        name: 'Community Food Bank',
        description: 'Collects and distributes food to families in need',
        type: 'Food Bank',
        position: const LatLng(19.0650, 72.8750),
        icon: Icons.food_bank,
        color: Colors.red,
        address: 'Worli, Mumbai',
        timing: '9 AM - 6 PM',
        availableFood: ['Canned Food', 'Dry Grains', 'Packaged Items'],
        contact: '+91 98765 43212',
      ),
      LocationData(
        id: 'org_004',
        name: 'Akshaya Patra Foundation',
        description: 'Large-scale food distribution across Mumbai',
        type: 'NGO',
        position: const LatLng(19.0850, 72.8900),
        icon: Icons.volunteer_activism,
        color: Colors.green,
        address: 'Powai, Mumbai',
        timing: '8 AM - 7 PM',
        availableFood: ['Rice', 'Dal', 'Curry', 'Chapati', 'Pickles'],
        contact: '+91 98765 43213',
      ),
      LocationData(
        id: 'org_005',
        name: 'ITC Grand Central',
        description: 'Hotel chain donating surplus food',
        type: 'Hotel',
        position: const LatLng(19.0820, 72.8700),
        icon: Icons.hotel,
        color: Colors.orange,
        address: 'Parel, Mumbai',
        timing: 'Evening pickups',
        availableFood: ['Buffet Items', 'Fresh Salads', 'Beverages'],
        contact: '+91 98765 43214',
      ),
      LocationData(
        id: 'org_006',
        name: 'Robin Hood Army',
        description: 'Volunteer-based food redistribution network',
        type: 'NGO',
        position: const LatLng(19.0700, 72.8650),
        icon: Icons.volunteer_activism,
        color: Colors.green,
        address: 'Bandra West, Mumbai',
        timing: '7 PM - 11 PM',
        availableFood: ['Mixed Meals', 'Snacks', 'Fruits', 'Packaged Food'],
        contact: '+91 98765 43215',
      ),
    ]);
  }

  void _initializeMarkers() {
    // Create markers from the locations list
    for (var location in _locations) {
      _markers.add(
        Marker(
          point: location.position,
          width: 100,
          height: 100,
          child: GestureDetector(
            onTap: () {
              _showOrganizationDetails(location);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom marker with shadow
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: location.color, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(location.icon, color: location.color, size: 28),
                ),
                const SizedBox(height: 4),
                // Organization name tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: location.color,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    location.name.split(' ').first, // First word of name
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showOrganizationDetails(LocationData location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header with icon and name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: location.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            location.icon,
                            color: location.color,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: location.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  location.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: location.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Description
                    Text(
                      location.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Info cards
                    _buildInfoCard(
                      Icons.location_on,
                      'Location',
                      location.address,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.access_time,
                      'Operating Hours',
                      location.timing,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.phone,
                      'Contact',
                      location.contact,
                      Colors.green,
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _moveToLocation(location);
                            },
                            icon: const Icon(Icons.map, size: 20),
                            label: const Text('View on Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Navigate to organization's listing page
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Viewing ${location.name}\'s listings...',
                                  ),
                                  backgroundColor: const Color(0xFFE07A3E),
                                ),
                              );
                            },
                            icon: const Icon(Icons.list_alt, size: 20),
                            label: const Text('View Listings'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE07A3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _moveToLocation(LocationData location) {
    _mapController.move(location.position, 16.0);
  }

  Widget _buildLocationCard(LocationData location, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLocation = location;
        });
        _moveToLocation(location);
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE07A3E).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFE07A3E) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: location.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(location.icon, color: location.color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: location.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          location.type,
                          style: TextStyle(
                            fontSize: 9,
                            color: location.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location.address,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _recenterMap() {
    if (!_isLoadingLocation && _locationError == null) {
      _mapController.move(_currentPosition, 14.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking permission
    if (_isCheckingPermission) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: CommonFooter(user: widget.user),
      );
    }

    // Show permission request screen if no permission
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Permission request content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Location icon
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEEDD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 80,
                            color: Color(0xFFE07A3E),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'Location Access Required',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Description
                        const Text(
                          'To show nearby food donation centers, NGOs, and hotels on the map, we need access to your location.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Permission benefits
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEEDD),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBenefitItem(
                                Icons.restaurant,
                                'Find nearby hotels donating food',
                              ),
                              const SizedBox(height: 12),
                              _buildBenefitItem(
                                Icons.volunteer_activism,
                                'Locate NGOs accepting donations',
                              ),
                              const SizedBox(height: 12),
                              _buildBenefitItem(
                                Icons.food_bank,
                                'Discover food banks in your area',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Error message if any
                        if (_locationError != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationError!,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Grant permission button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoadingLocation
                                ? null
                                : _requestLocationPermission,
                            icon: _isLoadingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.location_on),
                            label: Text(
                              _isLoadingLocation
                                  ? 'Requesting...'
                                  : 'Grant Location Access',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE07A3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CommonFooter(user: widget.user),
      );
    }

    // Show map if permission granted
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Cream background section with icon and description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFFFCEEDD)),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/nearby.png',
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.map, size: 48);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find Nearby Receivers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover hotels, NGOs, and food banks near you',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // Map section
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 14.0,
                      minZoom: 5.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.crumbchain.app',
                        maxNativeZoom: 19,
                        maxZoom: 19,
                        tileProvider: NetworkTileProvider(),
                        errorImage: const NetworkImage(
                          'https://via.placeholder.com/256?text=Map+Tile+Error',
                        ),
                        fallbackUrl:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        keepBuffer: 2,
                        retinaMode: true,
                      ),
                      MarkerLayer(markers: _markers),
                      // Current position marker
                      if (!_isLoadingLocation && _locationError == null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition,
                              width: 60,
                              height: 60,
                              child: const Column(
                                children: [
                                  Icon(
                                    Icons.my_location,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                  Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Loading indicator
                  if (_isLoadingLocation)
                    Container(
                      color: Colors.white.withOpacity(0.8),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Getting your location...'),
                          ],
                        ),
                      ),
                    ),

                  // Error message with retry button
                  if (_locationError != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _locationError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isLoadingLocation = true;
                                  _locationError = null;
                                });
                                _getCurrentLocation();
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Request Permission Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE07A3E),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Recenter button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FloatingActionButton(
                      onPressed: _recenterMap,
                      backgroundColor: const Color(0xFFE07A3E),
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),

                  // Legend
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('NGO', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.hotel, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text('Hotel', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.food_bank,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Food Bank', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Debug location info
                  Positioned(
                    bottom: 80,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Current Location:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${_currentPosition.latitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          Text(
                            'Lng: ${_currentPosition.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Side panel with location list
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    height: 200,
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width - 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE07A3E),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Nearby Locations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Location list
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(12),
                                itemCount: _locations.length,
                                itemBuilder: (context, index) {
                                  final location = _locations[index];
                                  final isSelected =
                                      _selectedLocation == location;
                                  return _buildLocationCard(
                                    location,
                                    isSelected,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CommonFooter(user: widget.user),
    );
  }
}

// Location data model
class LocationData {
  final String id; // Organization ID
  final String name;
  final String description;
  final String type; // 'NGO', 'Hotel', 'Food Bank'
  final LatLng position;
  final IconData icon;
  final Color color;
  final String address;
  final String timing;
  final List<String> availableFood; // Types of food available
  final String contact; // Contact information

  LocationData({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.position,
    required this.icon,
    required this.color,
    required this.address,
    required this.timing,
    required this.availableFood,
    required this.contact,
  });
}
