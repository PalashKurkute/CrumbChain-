import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/requirement.dart';
import '../services/requirement_service.dart';
import '../widgets/common_footer.dart';

class RequirementsMapPage extends StatefulWidget {
  const RequirementsMapPage({super.key});

  @override
  State<RequirementsMapPage> createState() => _RequirementsMapPageState();
}

// Helper class to track requirement with distance
class RequirementWithDistance {
  final Requirement requirement;
  final double? distance; // Distance in kilometers
  final LatLng coordinates;

  RequirementWithDistance({
    required this.requirement,
    this.distance,
    required this.coordinates,
  });
}

class _RequirementsMapPageState extends State<RequirementsMapPage> {
  final MapController _mapController = MapController();
  List<RequirementWithDistance> _requirementsWithDistance = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current location
      Position? position = await _getCurrentLocation();
      
      // Fetch active requirements
      List<Requirement> requirements = await RequirementService.getRequirements(
        status: 'active',
      );

      print('📍 Fetched ${requirements.length} requirements');

      // Filter requirements that have valid coordinates
      List<RequirementWithDistance> requirementsWithCoords = [];

      for (var requirement in requirements) {
        if (requirement.latitude != null && requirement.longitude != null) {
          LatLng coords = LatLng(requirement.latitude!, requirement.longitude!);
          
          // Calculate distance if we have user's location
          double? distance;
          if (position != null) {
            distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              requirement.latitude!,
              requirement.longitude!,
            ) / 1000; // Convert to kilometers
          }

          requirementsWithCoords.add(RequirementWithDistance(
            requirement: requirement,
            distance: distance,
            coordinates: coords,
          ));
        }
      }

      // Sort by distance (closest first)
      requirementsWithCoords.sort((a, b) {
        if (a.distance == null && b.distance == null) return 0;
        if (a.distance == null) return 1;
        if (b.distance == null) return -1;
        return a.distance!.compareTo(b.distance!);
      });

      if (mounted) {
        setState(() {
          _requirementsWithDistance = requirementsWithCoords;
          _currentPosition = position;
          _isLoading = false;
        });

        // Move map to user's location or first requirement after widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            try {
              if (position != null) {
                _mapController.move(
                  LatLng(position.latitude, position.longitude),
                  12.0,
                );
              } else if (requirementsWithCoords.isNotEmpty) {
                _mapController.move(requirementsWithCoords.first.coordinates, 11.0);
              }
            } catch (e) {
              print('⚠️ Could not move map: $e');
            }
          }
        });
      }
    } catch (e) {
      print('❌ Error loading requirements: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('📍 Current location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Add requirement markers
    for (int i = 0; i < _requirementsWithDistance.length; i++) {
      final reqWithDist = _requirementsWithDistance[i];
      final isSelected = _selectedIndex == i;

      markers.add(
        Marker(
          point: reqWithDist.coordinates,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = i;
              });
              _showRequirementDetails(reqWithDist);
            },
            child: Icon(
              Icons.location_pin,
              size: isSelected ? 50 : 40,
              color: isSelected ? Colors.red : const Color(0xFF20B2AA),
              shadows: const [
                Shadow(
                  blurRadius: 3,
                  color: Colors.black26,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Add current location marker if available
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 30,
          height: 30,
          child: const Icon(
            Icons.my_location,
            size: 30,
            color: Colors.blue,
            shadows: [
              Shadow(
                blurRadius: 3,
                color: Colors.black26,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  void _showRequirementDetails(RequirementWithDistance reqWithDist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              reqWithDist.requirement.organizationType == 'NGO'
                  ? Icons.volunteer_activism
                  : Icons.home,
              color: const Color(0xFFE07A3E),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                reqWithDist.requirement.organizationName,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                Icons.business,
                'Type',
                reqWithDist.requirement.organizationType,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.schedule,
                'Operating Hours',
                reqWithDist.requirement.operatingHours,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                Icons.people,
                'Crowd Size',
                '${reqWithDist.requirement.crowdSize} people',
              ),
              const SizedBox(height: 8),
              if (reqWithDist.requirement.category != null)
                _buildDetailRow(
                  Icons.restaurant,
                  'Category',
                  reqWithDist.requirement.category!,
                ),
              if (reqWithDist.requirement.category != null)
                const SizedBox(height: 8),
              if (reqWithDist.requirement.foodPreferenceTag != null)
                _buildDetailRow(
                  Icons.dining,
                  'Food Preference',
                  reqWithDist.requirement.foodPreferenceTag!,
                ),
              if (reqWithDist.requirement.foodPreferenceTag != null)
                const SizedBox(height: 8),
              if (reqWithDist.requirement.location != null)
                _buildDetailRow(
                  Icons.location_on,
                  'Location',
                  reqWithDist.requirement.location!,
                ),
              if (reqWithDist.requirement.location != null)
                const SizedBox(height: 8),
              if (reqWithDist.distance != null)
                _buildDetailRow(
                  Icons.directions,
                  'Distance',
                  '${reqWithDist.distance!.toStringAsFixed(1)} km away',
                ),
              if (reqWithDist.distance != null) const SizedBox(height: 8),
              if (reqWithDist.requirement.contactPerson != null)
                _buildDetailRow(
                  Icons.person,
                  'Contact Person',
                  reqWithDist.requirement.contactPerson!,
                ),
              if (reqWithDist.requirement.contactPerson != null)
                const SizedBox(height: 8),
              if (reqWithDist.requirement.contactPhone != null)
                _buildDetailRow(
                  Icons.phone,
                  'Phone',
                  reqWithDist.requirement.contactPhone!,
                ),
              if (reqWithDist.requirement.contactPhone != null)
                const SizedBox(height: 8),
              if (reqWithDist.requirement.additionalNotes != null &&
                  reqWithDist.requirement.additionalNotes!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.black54),
                        SizedBox(width: 4),
                        Text(
                          'Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(reqWithDist.requirement.additionalNotes!),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to donate/fulfill requirement page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact feature coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.volunteer_activism),
            label: const Text('Contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE07A3E),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Receivers'),
        backgroundColor: const Color(0xFFE07A3E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequirements,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading requirements',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRequirements,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _requirementsWithDistance.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Requirements Found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'There are no active receiver requirements at the moment.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        // Map
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition != null
                                ? LatLng(_currentPosition!.latitude,
                                    _currentPosition!.longitude)
                                : _requirementsWithDistance.isNotEmpty
                                    ? _requirementsWithDistance.first.coordinates
                                    : const LatLng(19.0760, 72.8777),
                            initialZoom: 12.0,
                            minZoom: 5.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.crumbchain',
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                          ],
                        ),
                        // Bottom card list
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 180,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.white,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              itemCount: _requirementsWithDistance.length,
                              itemBuilder: (context, index) {
                                final reqWithDist =
                                    _requirementsWithDistance[index];
                                final isSelected = _selectedIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                    _mapController.move(
                                      reqWithDist.coordinates,
                                      14.0,
                                    );
                                  },
                                  child: _buildRequirementCard(
                                    reqWithDist,
                                    isSelected,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
      bottomNavigationBar: const CommonFooter(selectedIndex: 1),
    );
  }

  Widget _buildRequirementCard(
    RequirementWithDistance reqWithDist,
    bool isSelected,
  ) {
    return Container(
      width: 280,
      height: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF20B2AA) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Organization name
            Row(
              children: [
                Icon(
                  reqWithDist.requirement.organizationType == 'NGO'
                      ? Icons.volunteer_activism
                      : Icons.home,
                  size: 18,
                  color: const Color(0xFFE07A3E),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    reqWithDist.requirement.organizationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Category and crowd size
            Text(
              '${reqWithDist.requirement.category ?? "Food"} • ${reqWithDist.requirement.crowdSize} people',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Operating hours
            Text(
              reqWithDist.requirement.operatingHours,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Distance badge
            if (reqWithDist.distance != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A3E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: Color(0xFFE07A3E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reqWithDist.distance!.toStringAsFixed(1)} km',
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
      ),
    );
  }
}
