import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/common_footer.dart';
import '../models/user.dart';
import '../models/listing.dart';
import '../services/listing_service.dart';
import 'create_listing_page.dart';

class ListingTrackerPage extends StatefulWidget {
  final User? user;

  const ListingTrackerPage({super.key, this.user});

  @override
  State<ListingTrackerPage> createState() => _ListingTrackerPageState();
}

class _ListingTrackerPageState extends State<ListingTrackerPage> {
  final ListingService _listingService = ListingService();
  List<Listing> _activeListings = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadActiveListings();
    // Auto-refresh every 30 seconds to show real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadActiveListings();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveListings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user's listings with status: active, claimed, approved, in_transit, out_for_delivery (not completed/delivered)
      final result = await _listingService.getListings(
        userOnly: true,
        status: 'active,claimed,approved,in_transit,out_for_delivery',
      );

      if (result['success'] == true) {
        final List<dynamic> listingsJson = result['listings'] ?? [];
        setState(() {
          _activeListings = listingsJson
              .map((json) => Listing.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load listings';
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
            icon: const Icon(Icons.refresh, color: Color(0xFFE07A3E)),
            onPressed: _isLoading ? null : _loadActiveListings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
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
                      'assets/images/listing-tracker.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_shipping,
                          size: 48,
                          color: Colors.black87,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Listing Tracker',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Track all your food donation listings in real-time and monitor their delivery status',
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

            // Live tracking indicator
            if (_activeListings.any(
              (listing) =>
                  listing.orderStatus == 'in_transit' ||
                  listing.orderStatus == 'out_for_delivery',
            )) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF20B2AA), Color(0xFF48B2A5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF20B2AA).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '🚚 Live Tracking Active - Auto-updating every 30s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Body Content - Active Listings from Backend
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE07A3E),
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadActiveListings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE07A3E),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _activeListings.isEmpty
                  ? Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No active listings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a new listing to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadActiveListings,
                      color: const Color(0xFFE07A3E),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeListings.length,
                        itemBuilder: (context, index) {
                          final listing = _activeListings[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildListingCard(listing),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CommonFooter(user: widget.user),
    );
  }

  Widget _buildListingCard(Listing listing) {
    // Determine status display based on listing status
    String statusText;
    Color statusColor;
    IconData? statusIcon;

    if (listing.status == 'claimed') {
      statusText = 'Claimed - Pending Approval';
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (listing.status == 'approved') {
      statusText = 'Approved - Awaiting Driver';
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
    } else if (listing.status == 'in_transit') {
      statusText = 'Driver En Route';
      statusColor = const Color(0xFF20B2AA);
      statusIcon = Icons.local_shipping;
    } else if (listing.status == 'out_for_delivery') {
      statusText = 'Out for Delivery';
      statusColor = const Color(0xFF20B2AA);
      statusIcon = Icons.delivery_dining;
    } else if (listing.status == 'active') {
      statusText = 'Active';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = listing.status;
      statusColor = Colors.grey;
    }

    // Calculate time ago
    final Duration difference = DateTime.now().difference(listing.createdAt);
    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo =
          '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      timeAgo =
          '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      timeAgo =
          '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
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
                  listing.foodType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit button (Pencil icon) - only for active listings
                  if (listing.status == 'active')
                    InkWell(
                      onTap: () async {
                        // Navigate to edit page (for now, just navigate to create page)
                        // TODO: Pass listing data for editing once CreateListingPage supports it
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateListingPage(
                              user: widget.user,
                              isEditing: true,
                            ),
                          ),
                        );
                        if (result == true) {
                          _loadActiveListings(); // Refresh the list
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Color(0xFFE07A3E),
                        ),
                      ),
                    ),
                  if (listing.status == 'active') const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (statusIcon != null) ...[
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (listing.description.isNotEmpty) ...[
            Text(
              listing.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.fastfood, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                listing.quantity,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.label, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                listing.dietaryTag,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  listing.location,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  timeAgo,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Driver information section (if driver has claimed the delivery)
          if (listing.driverId != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF20B2AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF20B2AA)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF20B2AA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver En Route',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF20B2AA),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              listing.driverName ?? 'Driver',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (listing.driverClaimedAt != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Picked up ${_formatTime(listing.driverClaimedAt!)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  // ETA Display
                  if (listing.driverClaimedAt != null &&
                      (listing.orderStatus == 'in_transit' ||
                          listing.orderStatus == 'out_for_delivery')) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFF20B2AA),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Estimated Arrival',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _calculateETA(listing.driverClaimedAt!),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF20B2AA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Receiver information (if order is claimed by receiver)
          if (listing.claimedByName != null && listing.driverId == null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Claimed by: ${listing.claimedByName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final Duration difference = DateTime.now().difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  String _calculateETA(DateTime pickupTime) {
    // Calculate estimated arrival based on pickup time
    // Assuming average delivery takes 20-40 minutes from pickup
    final Duration timeSincePickup = DateTime.now().difference(pickupTime);
    final int minutesSincePickup = timeSincePickup.inMinutes;

    // Estimated delivery window: 20-40 minutes from pickup
    const int minDeliveryTime = 20;
    const int maxDeliveryTime = 40;

    if (minutesSincePickup < minDeliveryTime) {
      // Still within the minimum time
      final int remainingMin = minDeliveryTime - minutesSincePickup;
      final int remainingMax = maxDeliveryTime - minutesSincePickup;
      return '$remainingMin-$remainingMax min';
    } else if (minutesSincePickup < maxDeliveryTime) {
      // Within the delivery window
      final int remainingMax = maxDeliveryTime - minutesSincePickup;
      return '5-$remainingMax min';
    } else {
      // Past the estimated window - should arrive soon
      return 'Arriving soon';
    }
  }
}
