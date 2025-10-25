import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../pages/change_password_page.dart';
import '../pages/settings_page.dart';
import '../pages/how_it_works_page.dart';

class ReceiverProfileMenu {
  static void show(BuildContext context, User user) {
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
              title: Row(
                children: [
                  Flexible(
                    child: Text(user.fullName, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    color: Color(0xFFE07A3E),
                    size: 18,
                  ),
                ],
              ),
              subtitle: Text(user.email),
              trailing: IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFFE07A3E),
                  size: 20,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showEditOrganizationDialog(context, user);
                },
                tooltip: 'Edit Profile',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFFE07A3E)),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangePasswordPage(user: user),
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
                    builder: (context) => SettingsPage(user: user),
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
                    builder: (context) => HowItWorksPage(user: user),
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
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomePage()),
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

  static void _showEditOrganizationDialog(BuildContext context, User user) {
    final TextEditingController orgNameController = TextEditingController(
      text: user.fullName,
    );
    final TextEditingController orgEmailController = TextEditingController(
      text: user.email,
    );
    final TextEditingController locationController = TextEditingController();
    File? selectedImage;
    bool isLoadingLocation = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Organization Profile',
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
                                    Icons.business,
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
                // Organization Name Field
                TextField(
                  controller: orgNameController,
                  decoration: InputDecoration(
                    labelText: 'Organization Name',
                    prefixIcon: const Icon(
                      Icons.business,
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
                // Organization Email Field
                TextField(
                  controller: orgEmailController,
                  decoration: InputDecoration(
                    labelText: 'Organization Email',
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
                const SizedBox(height: 16),
                // Location Field with Geolocation
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: 'Organization Location',
                    prefixIcon: const Icon(
                      Icons.location_on,
                      color: Color(0xFFE07A3E),
                    ),
                    suffixIcon: isLoadingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE07A3E),
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Color(0xFFE07A3E),
                            ),
                            onPressed: () async {
                              setDialogState(() {
                                isLoadingLocation = true;
                              });

                              try {
                                // Check permissions
                                LocationPermission permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                  if (permission == LocationPermission.denied) {
                                    throw Exception(
                                      'Location permissions are denied',
                                    );
                                  }
                                }

                                if (permission ==
                                    LocationPermission.deniedForever) {
                                  throw Exception(
                                    'Location permissions are permanently denied',
                                  );
                                }

                                // Get current position
                                Position position =
                                    await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    );

                                // Reverse geocoding
                                List<Placemark> placemarks =
                                    await placemarkFromCoordinates(
                                      position.latitude,
                                      position.longitude,
                                    );

                                if (placemarks.isNotEmpty) {
                                  Placemark place = placemarks[0];

                                  // Fuzzy logic: Build address from available components
                                  List<String> addressParts = [];

                                  if (place.street != null &&
                                      place.street!.isNotEmpty) {
                                    addressParts.add(place.street!);
                                  }
                                  if (place.subLocality != null &&
                                      place.subLocality!.isNotEmpty) {
                                    addressParts.add(place.subLocality!);
                                  }
                                  if (place.locality != null &&
                                      place.locality!.isNotEmpty) {
                                    addressParts.add(place.locality!);
                                  }
                                  if (place.administrativeArea != null &&
                                      place.administrativeArea!.isNotEmpty) {
                                    addressParts.add(place.administrativeArea!);
                                  }
                                  if (place.postalCode != null &&
                                      place.postalCode!.isNotEmpty) {
                                    addressParts.add(place.postalCode!);
                                  }

                                  // Filter out duplicates and join
                                  String address = addressParts
                                      .where((part) => part.isNotEmpty)
                                      .toSet()
                                      .join(', ');

                                  if (address.isEmpty) {
                                    address =
                                        place.locality ?? 'Current location';
                                  }

                                  setDialogState(() {
                                    locationController.text = address;
                                    isLoadingLocation = false;
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Location detected successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                setDialogState(() {
                                  isLoadingLocation = false;
                                });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
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
                    hintText: 'Tap location icon to auto-detect',
                  ),
                  maxLines: 2,
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
              onPressed: () async {
                // Validate input
                if (orgNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Organization name cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (orgEmailController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE07A3E)),
                  ),
                );

                // Call API to update profile
                final authService = AuthService();
                final result = await authService.updateProfile(
                  fullName: orgNameController.text.trim(),
                  email: orgEmailController.text.trim(),
                  imagePath: selectedImage?.path,
                  location: locationController.text.trim(),
                );

                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }

                if (result['success'] == true) {
                  if (context.mounted) {
                    // Close edit dialog
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Organization profile updated successfully! Please restart the app to see changes.',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result['message'] ?? 'Failed to update profile',
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
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
}
