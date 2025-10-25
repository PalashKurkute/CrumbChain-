import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/common_footer.dart';
import '../widgets/driver_profile_menu.dart';
import 'driver_orders_list_page.dart';
import 'driver_orders_map_page.dart';

class DriverHomePage extends StatefulWidget {
  final User user;

  const DriverHomePage({super.key, required this.user});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  int _selectedIndex = 1; // Start with Home selected (center)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Logo and Profile Button section
              Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Logo
                  Center(
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

                  // Profile Button positioned on the right
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        DriverProfileMenu.show(context, widget.user);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Image.asset(
                          'assets/images/profile.png',
                          width: 32,
                          height: 32,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.person,
                              size: 32,
                              color: Colors.black87,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Feature Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    _buildFeatureCard(
                      imagePath: 'assets/images/checklist.png',
                      label: 'Explore Orders',
                      color: const Color(0xFFE07A3E),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/listing-history.png',
                      label: 'Order History',
                      color: const Color(0xFF20B2AA),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/incentives.png',
                      label: 'Perks & Rewards',
                      color: const Color(0xFFFFD700),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/success-stories.png',
                      label: 'Impact Stories',
                      color: const Color(0xFF9C27B0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: CommonFooter(
        selectedIndex: _selectedIndex,
        user: widget.user,
      ),
    );
  }

  Widget _buildFeatureCard({
    IconData? icon,
    String? imagePath,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        if (label == 'Explore Orders') {
          _showExploreOrdersDialog(context);
        } else if (label == 'Order History') {
          // TODO: Navigate to driver order history
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order History - Coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (label == 'Perks & Rewards') {
          // TODO: Navigate to driver perks and rewards
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perks & Rewards - Coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        } else if (label == 'Impact Stories') {
          // TODO: Navigate to impact stories
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impact Stories - Coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCEEDD), // Cream background for cards
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: imagePath != null
                  ? Image.asset(
                      imagePath,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          icon ?? Icons.info,
                          size: 48,
                          color: Colors.black87,
                        );
                      },
                    )
                  : Icon(icon ?? Icons.info, size: 48, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExploreOrdersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delivery_dining, color: Color(0xFFE07A3E)),
            SizedBox(width: 12),
            Text('Explore Orders'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose how you want to view available orders:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            
            // List View Option
            _buildViewOption(
              context: context,
              icon: Icons.list,
              title: 'List View',
              description: 'View orders in a detailed list',
              color: const Color(0xFFE07A3E),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverOrdersListPage(user: widget.user),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Map View Option
            _buildViewOption(
              context: context,
              icon: Icons.map,
              title: 'Map View',
              description: 'View orders on a map',
              color: const Color(0xFF20B2AA),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverOrdersMapPage(user: widget.user),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
