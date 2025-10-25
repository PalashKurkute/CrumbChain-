import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';

class CreateListingPage extends StatefulWidget {
  final User? user;
  final bool isEditing;

  const CreateListingPage({
    super.key,
    this.user,
    this.isEditing = false,
  });

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _foodTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController = TextEditingController();
  
  // Image
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  
  // Dropdowns and selections
  String? _selectedDietaryTag;
  String? _selectedTemperatureStatus;
  String? _selectedPackagingType;
  
  // Date prepared
  DateTime? _datePrepared;
  
  // Pickup time
  TimeOfDay? _pickupTime;
  
  // Payment toggle
  bool _isPaidDonation = false;
  
  // Loading state for location
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        // TODO: Implement AI image analysis here
        _analyzeImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _analyzeImage() {
    // TODO: Implement AI image analysis with backend
    // This will analyze the image and populate food type and description
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analyzing image...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Image Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE07A3E)),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFE07A3E),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _datePrepared ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 2)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE07A3E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _datePrepared) {
      setState(() {
        _datePrepared = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE07A3E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickupTime) {
      setState(() {
        _pickupTime = picked;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permissions are permanently denied. Please enable in settings.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates using geocoding with fuzzy logic
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Build address with fuzzy logic - include available components
        List<String> addressParts = [];
        
        // Add street/name if available
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        } else if (place.name != null && place.name!.isNotEmpty) {
          addressParts.add(place.name!);
        }
        
        // Add sublocality if available
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        
        // Add locality (city/town)
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        
        // Add state if available
        if (place.administrativeArea != null && 
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        
        // Add postal code if available
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        // Join with fuzzy logic - filter out duplicates and empty strings
        String address = addressParts
            .where((part) => part.isNotEmpty)
            .toSet()
            .join(', ');
        
        // Fallback to a basic description if no address found
        if (address.isEmpty) {
          address = '${place.locality ?? 'Unknown location'}';
        }
        
        setState(() {
          _locationController.text = address;
          _isLoadingLocation = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location detected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // No placemark found, use a generic message
        setState(() {
          _locationController.text = 'Current location';
          _isLoadingLocation = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location detected! Please add more details.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _foodTypeController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    super.dispose();
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
                      'assets/images/camera.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: Colors.black87,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.isEditing
                        ? 'Edit Food Listing'
                        : 'Create Food Listing',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Share your surplus food and help those in need',
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

            // Form Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Add Photo Section (Image Analysis)
                    const Text(
                      '1. Upload Food Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI will analyze your image to identify food type',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEEDD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _imageFile != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          color: Color(0xFFE07A3E),
                                        ),
                                        onPressed: _showImageSourceDialog,
                                        tooltip: 'Retake Photo',
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Click to add photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Food Type and Description
                    const Text(
                      'Food Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _foodTypeController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Biryani, Pizza, Salad',
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.restaurant_menu),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter food type';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe the food, ingredients, etc.',
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Quantity Confirmation
                    const Text(
                      '2. Quantity Confirmation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Serves 10 people, 5 kg, 20 boxes',
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.scale),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter quantity';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 3. Date Prepared
                    const Text(
                      '3. Date Food Was Prepared',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEEDD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFFE07A3E),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _datePrepared != null
                                  ? DateFormat('MMM dd, yyyy').format(
                                      _datePrepared!,
                                    )
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _datePrepared != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. Dietary Tag
                    const Text(
                      '4. Dietary Tag',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedDietaryTag,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.restaurant),
                      ),
                      hint: const Text('Select an option'),
                      items: ['Veg', 'Non-Veg', 'Jain', 'Halal']
                          .map(
                            (tag) => DropdownMenuItem(
                              value: tag,
                              child: Text(tag),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDietaryTag = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a dietary tag';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 5. Temperature Status
                    const Text(
                      '5. Temperature Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTemperatureStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.thermostat),
                      ),
                      hint: const Text('Select an option'),
                      items: [
                        'Hot/Freshly cooked',
                        'Refrigerated/chilled',
                        'Shelf-stable/ambient',
                      ]
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTemperatureStatus = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select temperature status';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 6. Pickup Location and Time
                    const Text(
                      '6. Pickup Location & Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter pickup address',
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: IconButton(
                          icon: Icon(
                            _isLoadingLocation 
                                ? Icons.hourglass_empty 
                                : Icons.my_location,
                            color: const Color(0xFFE07A3E),
                          ),
                          onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                          tooltip: 'Use current location',
                        ),
                        suffixIcon: const Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter pickup location';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Preferred Pickup Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEEDD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFFE07A3E),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _pickupTime != null
                                  ? _pickupTime!.format(context)
                                  : 'Select time',
                              style: TextStyle(
                                fontSize: 16,
                                color: _pickupTime != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 7. Packaging Type
                    const Text(
                      '7. Packaging Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedPackagingType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.inventory_2),
                      ),
                      hint: const Text('Select an option'),
                      items: [
                        'Bulk container',
                        'Individual boxes',
                        'Sealed bags',
                      ]
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPackagingType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select packaging type';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 8. Payment Toggle
                    const Text(
                      '8. Donation Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEEDD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Free',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isPaidDonation 
                                          ? Colors.grey.shade600 
                                          : const Color(0xFFE07A3E),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '/',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Selling price',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _isPaidDonation 
                                          ? const Color(0xFFE07A3E)
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isPaidDonation,
                                activeColor: const Color(0xFFE07A3E),
                                onChanged: (value) {
                                  setState(() {
                                    _isPaidDonation = value;
                                    if (!value) {
                                      _amountController.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_isPaidDonation) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter amount (₹)',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.currency_rupee),
                              ),
                              validator: (value) {
                                if (_isPaidDonation &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter amount';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_imageFile == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please upload a food image'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (_datePrepared == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select date prepared'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            if (_pickupTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select pickup time',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // TODO: Submit listing to backend
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.isEditing
                                      ? 'Listing updated successfully!'
                                      : 'Listing created successfully!',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE07A3E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.isEditing
                              ? 'Update Listing'
                              : 'Create Listing',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CommonFooter(user: widget.user),
    );
  }
}
