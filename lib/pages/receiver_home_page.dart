import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/common_footer.dart';
import '../widgets/receiver_profile_menu.dart';
import 'create_requirements_page.dart';
import 'listings_map_page.dart';
import 'order_history_page.dart';
import 'live_order_tracker_page.dart';
import 'rewards_page.dart';

class ReceiverHomePage extends StatefulWidget {
  final User user;

  const ReceiverHomePage({super.key, required this.user});

  @override
  State<ReceiverHomePage> createState() => _ReceiverHomePageState();
}

class _ReceiverHomePageState extends State<ReceiverHomePage> {
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
                        ReceiverProfileMenu.show(context, widget.user);
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

              const SizedBox(height: 24),

              // Feature Cards Grid - 4 cards for receivers
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    _buildFeatureCard(
                      imagePath: 'assets/images/requirements.png',
                      label: 'Requirements List',
                      color: const Color(0xFF20B2AA),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/explore.png',
                      label: 'Explore Listings',
                      color: const Color(0xFF48B2A5),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/order-history.png',
                      label: 'Order History',
                      color: const Color(0xFF20B2AA),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/live-tracker.png',
                      label: 'Live Order Tracker',
                      color: const Color(0xFF48B2A5),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/rewards.png',
                      label: 'My Rewards',
                      color: const Color(0xFFFFD700),
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
        if (label == 'Requirements List') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRequirementsPage(user: widget.user),
            ),
          );
        } else if (label == 'Explore Listings') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingsMapPage(user: widget.user),
            ),
          );
        } else if (label == 'Order History') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderHistoryPage(user: widget.user),
            ),
          );
        } else if (label == 'Live Order Tracker') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveOrderTrackerPage(user: widget.user),
            ),
          );
        } else if (label == 'My Rewards') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RewardsPage(user: widget.user),
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
}
