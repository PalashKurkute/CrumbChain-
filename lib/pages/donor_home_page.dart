import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../widgets/common_footer.dart';
import 'create_listing_page.dart';
import 'donate_stale_food_page.dart';
import 'listing_tracker_page.dart';
import 'listing_history_page.dart';
import 'recommend_schemes_page.dart';
import 'how_it_works_page.dart';
import 'impact_tracker_page.dart';
import 'nearby_page.dart';
import 'leaderboard_page.dart';
import 'change_password_page.dart';
import 'settings_page.dart';

class DonorHomePage extends StatefulWidget {
  final User user;

  const DonorHomePage({super.key, required this.user});

  @override
  State<DonorHomePage> createState() => _DonorHomePageState();
}

class _DonorHomePageState extends State<DonorHomePage> {
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
                                '142 Points',
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

              // Feature Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: [
                    _buildFeatureCard(
                      imagePath: 'assets/images/food-donation.png',
                      label: 'Donate Food',
                      color: const Color(0xFF20B2AA),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/nearby.png',
                      label: 'Nearby Receivers',
                      color: const Color(0xFF48B2A5),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/listing-history.png',
                      label: 'Listing History',
                      color: const Color(0xFF20B2AA),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/government_schemes.png',
                      label: 'Recommended Schemes',
                      color: const Color(0xFF48B2A5),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/listing-tracker.png',
                      label: 'Listing Tracker',
                      color: const Color(0xFF20B2AA),
                    ),
                    _buildFeatureCard(
                      imagePath: 'assets/images/impact tracker.png',
                      label: 'Impact Tracker',
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
        if (label == 'Donate Food') {
          _showDonateFoodDialog(context);
        } else if (label == 'Listing Tracker') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingTrackerPage(user: widget.user),
            ),
          );
        } else if (label == 'Listing History') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListingHistoryPage(user: widget.user),
            ),
          );
        } else if (label == 'Recommended Schemes') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecommendSchemesPage(user: widget.user),
            ),
          );
        } else if (label == 'Impact Tracker') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImpactTrackerPage(user: widget.user),
            ),
          );
        } else if (label == 'Nearby Receivers') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NearbyPage(user: widget.user),
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

  void _showDonateFoodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Donate Food',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How would you like to donate?',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Option 1: Create food listing
              InkWell(
                onTap: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateListingPage(user: widget.user),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEEDD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE07A3E)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE07A3E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/camera.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Create food listing by clicking picture',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Option 2: Donate stale food
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to stale food donation page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DonateStaleFoodPage(user: widget.user),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEEDD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'assets/images/stale.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.compost,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Donate stale food for manure generation',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: widget.user.fullName,
    );
    final TextEditingController emailController = TextEditingController(
      text: widget.user.email,
    );
    File? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Picture Section
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Choose Profile Picture',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ListTile(
                              leading: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFFE07A3E),
                              ),
                              title: const Text('Camera'),
                              onTap: () async {
                                Navigator.pop(context);
                                final XFile? pickedFile = await picker
                                    .pickImage(
                                      source: ImageSource.camera,
                                      maxWidth: 1800,
                                      maxHeight: 1800,
                                      imageQuality: 85,
                                    );
                                if (pickedFile != null) {
                                  setDialogState(() {
                                    selectedImage = File(pickedFile.path);
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.photo_library,
                                color: Color(0xFFE07A3E),
                              ),
                              title: const Text('Gallery'),
                              onTap: () async {
                                Navigator.pop(context);
                                final XFile? pickedFile = await picker
                                    .pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1800,
                                      maxHeight: 1800,
                                      imageQuality: 85,
                                    );
                                if (pickedFile != null) {
                                  setDialogState(() {
                                    selectedImage = File(pickedFile.path);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade200,
                          image: selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedImage == null
                            ? Image.asset(
                                'assets/images/profile.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE07A3E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Name Field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFFE07A3E),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE07A3E),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Email Field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFE07A3E),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE07A3E),
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement profile update logic
                // Update user data with nameController.text, emailController.text, and selectedImage
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07A3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text('Save Changes'),
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
          bottom: 10, // Reduced from 20 to fix overflow
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
              trailing: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFFE07A3E),
                  size: 20,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditProfileDialog(context);
                },
                tooltip: 'Edit Profile',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.leaderboard, color: Color(0xFFE07A3E)),
              title: const Text('Leaderboard'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaderboardPage(user: widget.user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.verified_user,
                color: Color(0xFFE07A3E),
              ),
              title: const Text('Compliance and CSRhub'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Compliance and CSRhub page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compliance and CSRhub - Coming soon'),
                    backgroundColor: Color(0xFFE07A3E),
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
            const SizedBox(height: 10), // Reduced from 20 to fix overflow
          ],
        ),
      ),
    );
  }
}
