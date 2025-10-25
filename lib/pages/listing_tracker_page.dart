import 'package:flutter/material.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';
import 'create_listing_page.dart';

class ListingTrackerPage extends StatefulWidget {
  final User? user;

  const ListingTrackerPage({super.key, this.user});

  @override
  State<ListingTrackerPage> createState() => _ListingTrackerPageState();
}

class _ListingTrackerPageState extends State<ListingTrackerPage> {
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

            const SizedBox(height: 24),

            // Body Content - Active Listings
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildListingCard(
                    title: 'Cooked Rice and Curry',
                    foodType: 'Cooked Food',
                    quantity: '10 plates',
                    location: 'Andheri West, Mumbai',
                    description:
                        'Fresh cooked rice with curry, ready for pickup',
                    status: 'In Transit',
                    statusColor: Colors.orange,
                    time: '2 hours ago',
                  ),

                  const SizedBox(height: 12),

                  _buildListingCard(
                    title: 'Fresh Vegetables',
                    foodType: 'Raw Food',
                    quantity: '5 kg',
                    location: 'Bandra East, Mumbai',
                    description:
                        'Assorted fresh vegetables including tomatoes, onions, and greens',
                    status: 'Delivered',
                    statusColor: Colors.green,
                    time: '1 day ago',
                  ),

                  const SizedBox(height: 12),

                  _buildListingCard(
                    title: 'Packaged Snacks',
                    foodType: 'Packaged Food',
                    quantity: '20 packets',
                    location: 'Powai, Mumbai',
                    description: 'Sealed packaged snacks with long shelf life',
                    status: 'Pending Pickup',
                    statusColor: Colors.blue,
                    time: '3 hours ago',
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

  Widget _buildListingCard({
    required String title,
    required String foodType,
    required String quantity,
    required String location,
    required String description,
    required String status,
    required Color statusColor,
    required String time,
    String? imagePath,
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
                child: Text(
                  title,
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
                  // Edit button (Pencil icon)
                  InkWell(
                    onTap: () {
                      // Navigate to edit page with pre-filled data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateListingPage(
                            user: widget.user,
                            isEditing: true,
                            existingFoodName: title,
                            existingFoodType: foodType,
                            existingQuantity: quantity,
                            existingLocation: location,
                            existingDescription: description,
                            existingImagePath: imagePath,
                          ),
                        ),
                      );
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
                  const SizedBox(width: 8),
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
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
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
                  time,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
