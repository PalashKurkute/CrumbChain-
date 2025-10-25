import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../widgets/common_footer.dart';
import 'how_it_works_page.dart';
import 'redeem_points_page.dart';
import 'change_password_page.dart';
import 'settings_page.dart';
import 'create_requirements_page.dart';

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
                    child: Column(
                      children: [
                        Image.asset(
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
                        const SizedBox(height: 8),
                        // Points Display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEEDD),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE07A3E),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Color(0xFFE07A3E),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '85 Points',
                                style: TextStyle(
                                  fontSize: 16,
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

                  // Profile Button positioned on the right
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        _showProfileMenu(context);
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
          // TODO: Navigate to explore listings page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Explore Listings feature coming soon!'),
              backgroundColor: Color(0xFFE07A3E),
            ),
          );
        } else if (label == 'Order History') {
          // TODO: Navigate to order history page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order History feature coming soon!'),
              backgroundColor: Color(0xFFE07A3E),
            ),
          );
        } else if (label == 'Live Order Tracker') {
          // TODO: Navigate to live order tracker page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Live Order Tracker feature coming soon!'),
              backgroundColor: Color(0xFFE07A3E),
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

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Image.asset(
                'assets/images/profile.png',
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, size: 40);
                },
              ),
              title: Text(widget.user.fullName),
              subtitle: Text(widget.user.email),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.card_giftcard,
                color: Color(0xFFE07A3E),
              ),
              title: const Text('Redeem Points'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RedeemPointsPage(user: widget.user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFFE07A3E)),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(user: widget.user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFFE07A3E)),
              title: const Text('Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsPage(user: widget.user),
                  ),
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/images/how_it_works.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.help_outline);
                },
              ),
              title: const Text('How it Works'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HowItWorksPage(user: widget.user),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Image.asset(
                'assets/images/logout.png',
                width: 24,
                height: 24,
                color: Colors.red,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.logout, color: Colors.red);
                },
              ),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final authService = AuthService();
                await authService.logout();
                if (context.mounted) {
                  // Pop the bottom sheet first
                  Navigator.pop(context);
                  // Then navigate to main, which will show the home page
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) {
                        // Import main.dart HomePage
                        return const HomePage();
                      },
                    ),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
