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

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    // Check permission status first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionStatus();
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

  void _initializeMarkers() {
    // Sample markers - Replace with actual data from your backend
    _markers.addAll([
      // NGOs
      Marker(
        point: const LatLng(19.0896, 72.8656),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMarkerDetails(
            'NGO - Feeding India',
            'Active food distribution center',
            'NGO',
          ),
          child: const Column(
            children: [
              Icon(Icons.volunteer_activism, color: Colors.green, size: 40),
              Text(
                'NGO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      // Hotels
      Marker(
        point: const LatLng(19.0760, 72.8777),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMarkerDetails(
            'Taj Hotel',
            'Donates excess food daily',
            'Hotel',
          ),
          child: const Column(
            children: [
              Icon(Icons.hotel, color: Colors.orange, size: 40),
              Text(
                'Hotel',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      // Food Banks
      Marker(
        point: const LatLng(19.0650, 72.8750),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMarkerDetails(
            'Community Food Bank',
            'Open 9 AM - 6 PM',
            'Food Bank',
          ),
          child: const Column(
            children: [
              Icon(Icons.food_bank, color: Colors.red, size: 40),
              Text(
                'Food Bank',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      // More NGOs
      Marker(
        point: const LatLng(19.0850, 72.8900),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMarkerDetails(
            'Akshaya Patra Foundation',
            'Large-scale food distribution',
            'NGO',
          ),
          child: const Column(
            children: [
              Icon(Icons.volunteer_activism, color: Colors.green, size: 40),
              Text(
                'NGO',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  void _showMarkerDetails(String name, String description, String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  type == 'NGO'
                      ? Icons.volunteer_activism
                      : type == 'Hotel'
                      ? Icons.hotel
                      : Icons.food_bank,
                  color: type == 'NGO'
                      ? Colors.green
                      : type == 'Hotel'
                      ? Colors.orange
                      : Colors.red,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Type: $type',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Implement contact or navigation functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contacting $name...')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE07A3E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Contact', style: TextStyle(fontSize: 16)),
              ),
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
              // Header with logo
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.restaurant, size: 50);
                      },
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Nearby',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Permission request content
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
            // Header with logo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.restaurant, size: 50);
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Nearby',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

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
                    'Find Nearby Donors & Recipients',
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
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.crumbchain.app',
                        errorImage: const NetworkImage(
                          'https://via.placeholder.com/256?text=Map+Tile+Error',
                        ),
                        fallbackUrl:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                    bottom: 20,
                    right: 20,
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
