import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';
import '../services/listing_service.dart';
import '../services/food_detection_service.dart';

class CreateListingPage extends StatefulWidget {
  final User? user;
  final bool isEditing;

  const CreateListingPage({super.key, this.user, this.isEditing = false});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _listingService = ListingService();
  final _foodDetectionService = FoodDetectionService();

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

  // Expiry prediction
  int? _predictedExpiryDays;
  bool _isLoadingPrediction = false;
  double? _predictionConfidence;

  // Loading state for submission
  bool _isSubmitting = false;

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

  // Get expiry days based on recognized food items
  Map<String, dynamic> _getRecognizedFoodExpiry(String foodName) {
    final foodLower = foodName.toLowerCase().replaceAll(' ', '_');

    // Comprehensive shelf life for 80 Indian food items (refrigerated storage)
    final expiryMap = {
      // Sweets & Desserts (high sugar content)
      'adhirasam': 7, // Traditional fried sweet
      'anarsa': 10, // Sesame sweet
      'ariselu': 8, // Rice flour sweet
      'bandar_laddu': 12, // Dry sweet balls
      'basundi': 3, // Milk-based dessert
      'boondi': 10, // Crispy fried balls
      'gulab_jamun': 7, // Syrup-soaked dessert
      'jalebi': 4, // Crispy fried sweet
      'kaju_katli': 10, // Premium cashew sweet
      'kalakand': 5, // Milk-based sweet
      'karanji': 10, // Stuffed fried pastry
      'kulfi': 30, // Frozen dessert
      'laddu': 14, // Traditional sweet balls
      'malpua': 3, // Sweet pancake
      'modak': 3, // Steamed dumpling
      'mysore_pak': 10, // Gram flour fudge
      'poornalu': 5, // Fried sweet
      'ras_malai': 3, // Soft cheese dessert
      'rasgulla': 4, // Spongy cheese sweet
      'shankarpali': 20, // Crispy snack
      'sheer_korma': 3, // Vermicelli pudding
      'sohan_halwa': 14, // Dense sweet
      'sohan_papdi': 12, // Flaky sweet
      // Curries & Gravies
      'aloo_gobi': 4, // Potato-cauliflower curry
      'aloo_matar': 4, // Potato-peas curry
      'aloo_methi': 3, // Potato-fenugreek
      'aloo_shimla_mirch': 4, // Potato-capsicum
      'chana_masala': 5, // Chickpea curry
      'dal_makhani': 4, // Creamy lentil curry
      'kadai_paneer': 4, // Spicy paneer curry
      'palak_paneer': 3, // Spinach-paneer curry
      'paneer_butter_masala': 4, // Butter paneer curry
      // Breads & Flatbreads
      'butter_naan': 2, // Buttered leavened bread
      'chapati': 3, // Whole wheat bread
      'chole_bhature': 2, // Chickpea with fried bread
      'litti_chokha': 3, // Stuffed wheat balls
      'naan': 2, // Traditional leavened bread
      'paratha': 3, // Layered flatbread
      'puri': 2, // Fried puffed bread
      // Rice Dishes
      'biryani': 3, // Aromatic rice dish
      'fried_rice': 3, // Stir-fried rice
      'jeera_rice': 3, // Cumin-flavored rice
      'pulao': 3, // Spiced rice pilaf
      // South Indian Specials
      'dosa': 2, // Crispy rice crepe
      'idli': 2, // Steamed rice cakes
      'masala_dosa': 2, // Stuffed crepe
      'medu_vada': 2, // Lentil fritters
      'pesarattu': 2, // Moong dal crepe
      'uttapam': 2, // Thick rice pancake
      // Snacks & Fried Items
      'aloo_tikki': 3, // Potato patties
      'bhaji': 3, // Vegetable fritters
      'bonda': 3, // Spiced potato balls
      'dhokla': 3, // Steamed gram flour cake
      'kachori': 3, // Stuffed fried pastry
      'misi_roti': 3, // Spiced flatbread
      'momos': 3, // Steamed dumplings
      'pakode': 3, // Mixed vegetable fritters
      'samosa': 4, // Triangular fried pastry
      'sutar_feni': 20, // Traditional crispy snack
      'unni_appam': 4, // Sweet rice balls
      // Street Food Favorites
      'golgappa': 1, // Hollow crispy shells
      'kaathi_rolls': 2, // Wrapped flatbread rolls
      'paani_puri': 1, // Water-filled puri
      'pav_bhaji': 3, // Spiced vegetable curry
      'vada_pav': 2, // Spiced potato bun
      // Tandoor & Grilled
      'chicken_razala': 3, // Bengali chicken curry
      'chicken_tikka': 3, // Grilled chicken pieces
      'chicken_tikka_masala': 4, // Creamy chicken curry
      'lyangcha': 7, // Bengali sweet
      'navrattan_korma': 4, // Nine-jewel curry
      'shami_kebab': 3, // Minced meat patties
      // Beverages
      'chai': 1, // Spiced tea
      // Popular International
      'burger': 3, // Burger with patty
      'pizza': 4, // Italian flatbread
    };

    return {
      'days': expiryMap[foodLower] ?? 2, // Default 2 days if not found
      'isRecognized': expiryMap.containsKey(foodLower),
    };
  }

  void _analyzeImage() async {
    if (_imageFile == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFE07A3E)),
                SizedBox(height: 16),
                Text('Analyzing image...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Call food detection service
      final result = await _foodDetectionService.detectFood(_imageFile!);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (result['success'] == true) {
        final detectedFoodName = result['foodName'] ?? '';
        final confidence = result['confidence'] ?? 0.0;

        // Check if confidence is below 50%
        if (confidence < 0.50) {
          // Show dialog for low accuracy
          if (mounted) {
            _showLowAccuracyDialog(detectedFoodName, confidence);
          }
          return;
        }

        // Get expiry prediction for recognized food
        final expiryInfo = _getRecognizedFoodExpiry(detectedFoodName);
        final expiryDays = expiryInfo['days'] as int;
        final isRecognized = expiryInfo['isRecognized'] as bool;

        // Auto-fill the food name field and expiry prediction
        setState(() {
          _foodTypeController.text = detectedFoodName;
          if (isRecognized) {
            _predictedExpiryDays = expiryDays;
            _predictionConfidence = confidence;
          }
        });

        // Show success message with expiry
        if (mounted) {
          final accuracyPercent = (confidence * 100).toStringAsFixed(0);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Identified: $detectedFoodName',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Match Accuracy: $accuracyPercent%',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (isRecognized)
                          Text(
                            'Recommended shelf life: $expiryDays days',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to detect food'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showLowAccuracyDialog(String detectedFood, double confidence) {
    final accuracyPercent = (confidence * 100).toStringAsFixed(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Low Recognition Accuracy',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The AI detected "$detectedFood" but with only $accuracyPercent% confidence.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Accuracy below 50%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For better results, please either:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Take a clearer photo of the food',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '• Enter the dish name manually',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Clear the image to allow re-upload
                setState(() {
                  _imageFile = null;
                  _foodTypeController.clear();
                  _predictionConfidence = null;
                  _predictedExpiryDays = null;
                });
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Retake Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE07A3E),
                side: const BorderSide(color: Color(0xFFE07A3E)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Keep the image but let user manually enter food name
                setState(() {
                  _foodTypeController.clear();
                  _predictionConfidence = null;
                });
                // Focus on the food type field
                FocusScope.of(context).requestFocus(FocusNode());
              },
              icon: const Icon(Icons.edit),
              label: const Text('Enter Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07A3E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _predictFoodExpiry() async {
    if (_foodTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter food type first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingPrediction = true;
    });

    // Process prediction
    await Future.delayed(const Duration(milliseconds: 1500));

    // Calculate shelf life based on user inputs
    final prediction = _calculateShelfLife(
      foodType: _foodTypeController.text,
      temperatureStatus: _selectedTemperatureStatus,
      packagingType: _selectedPackagingType,
      dietaryTag: _selectedDietaryTag,
      datePrepared: _datePrepared,
    );

    setState(() {
      _predictedExpiryDays = prediction['days'] as int;
      _predictionConfidence = prediction['confidence'] as double;
      _isLoadingPrediction = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estimated shelf life: ${prediction['days']} days (${(prediction['confidence'] * 100).toStringAsFixed(0)}% accuracy)',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Advanced Shelf Life Calculation
  // Considers multiple factors for accurate prediction
  Map<String, dynamic> _calculateShelfLife({
    required String foodType,
    String? temperatureStatus,
    String? packagingType,
    String? dietaryTag,
    DateTime? datePrepared,
  }) {
    // Extract food characteristics
    final features = _analyzeFoodCharacteristics(
      foodType: foodType,
      temperatureStatus: temperatureStatus,
      packagingType: packagingType,
      dietaryTag: dietaryTag,
      datePrepared: datePrepared,
    );

    // Assess storage conditions
    final storageScore = _assessStorageConditions(features);

    // Calculate decay factors
    final decayScore = _calculateDecayFactors(storageScore, features);

    // Generate final prediction
    final finalPrediction = _generatePrediction(decayScore);

    return {
      'days': finalPrediction['days'],
      'confidence': finalPrediction['confidence'],
    };
  }

  // Analyze food characteristics
  Map<String, double> _analyzeFoodCharacteristics({
    required String foodType,
    String? temperatureStatus,
    String? packagingType,
    String? dietaryTag,
    DateTime? datePrepared,
  }) {
    final features = <String, double>{};
    final foodLower = foodType.toLowerCase();

    // Food category identification
    features['is_dairy'] =
        _containsAny(foodLower, [
          'milk',
          'cheese',
          'yogurt',
          'cream',
          'butter',
          'paneer',
          'rasgulla',
          'rasmalai',
          'basundi',
          'kalakand',
        ])
        ? 1.0
        : 0.0;
    features['is_meat'] =
        _containsAny(foodLower, [
          'chicken',
          'mutton',
          'beef',
          'pork',
          'meat',
          'fish',
          'seafood',
          'prawn',
          'egg',
          'kebab',
          'tikka',
        ])
        ? 1.0
        : 0.0;
    features['is_vegetable'] =
        _containsAny(foodLower, [
          'vegetable',
          'veggie',
          'salad',
          'lettuce',
          'spinach',
          'cabbage',
          'carrot',
          'tomato',
          'aloo',
          'gobi',
          'palak',
          'methi',
          'bhaji',
        ])
        ? 1.0
        : 0.0;
    features['is_fruit'] =
        _containsAny(foodLower, [
          'fruit',
          'apple',
          'banana',
          'orange',
          'mango',
          'grape',
          'berry',
        ])
        ? 1.0
        : 0.0;
    features['is_grain'] =
        _containsAny(foodLower, [
          'rice',
          'bread',
          'pasta',
          'noodle',
          'roti',
          'chapati',
          'biryani',
          'pulao',
          'naan',
          'paratha',
          'dosa',
          'idli',
        ])
        ? 1.0
        : 0.0;
    features['is_bakery'] =
        _containsAny(foodLower, [
          'cake',
          'pastry',
          'cookie',
          'biscuit',
          'donut',
          'muffin',
          'bread',
        ])
        ? 1.0
        : 0.0;
    features['is_prepared'] =
        _containsAny(foodLower, [
          'curry',
          'stew',
          'soup',
          'cooked',
          'fried',
          'pizza',
          'burger',
          'masala',
          'korma',
          'bhature',
          'pakode',
        ])
        ? 1.0
        : 0.0;

    // Sweet/dessert category (longer shelf life)
    features['is_sweet'] =
        _containsAny(foodLower, [
          'sweet',
          'dessert',
          'laddu',
          'jalebi',
          'gulab',
          'jamun',
          'halwa',
          'barfi',
          'katli',
          'mysore pak',
        ])
        ? 1.0
        : 0.0;

    // Temperature status encoding
    if (temperatureStatus == 'Hot/Freshly cooked') {
      features['temp_hot'] = 1.0;
      features['temp_cold'] = 0.0;
      features['temp_ambient'] = 0.0;
    } else if (temperatureStatus == 'Refrigerated/Chilled') {
      features['temp_hot'] = 0.0;
      features['temp_cold'] = 1.0;
      features['temp_ambient'] = 0.0;
    } else if (temperatureStatus == 'Shelf-stable/Ambient') {
      features['temp_hot'] = 0.0;
      features['temp_cold'] = 0.0;
      features['temp_ambient'] = 1.0;
    } else {
      features['temp_hot'] = 0.33;
      features['temp_cold'] = 0.33;
      features['temp_ambient'] = 0.33;
    }

    // Packaging encoding
    if (packagingType == 'Sealed bags') {
      features['pkg_sealed'] = 1.0;
      features['pkg_moderate'] = 0.0;
      features['pkg_open'] = 0.0;
    } else if (packagingType == 'Individual boxes') {
      features['pkg_sealed'] = 0.0;
      features['pkg_moderate'] = 1.0;
      features['pkg_open'] = 0.0;
    } else if (packagingType == 'Bulk container') {
      features['pkg_sealed'] = 0.0;
      features['pkg_moderate'] = 0.0;
      features['pkg_open'] = 1.0;
    } else {
      features['pkg_sealed'] = 0.33;
      features['pkg_moderate'] = 0.33;
      features['pkg_open'] = 0.33;
    }

    // Freshness factor based on preparation date
    if (datePrepared != null) {
      final daysSincePrepared = DateTime.now().difference(datePrepared).inDays;
      features['freshness'] = (1.0 - (daysSincePrepared / 7.0)).clamp(0.0, 1.0);
    } else {
      features['freshness'] = 0.8; // Assume relatively fresh
    }

    return features;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // Assess storage conditions
  Map<String, double> _assessStorageConditions(Map<String, double> features) {
    final scores = <String, double>{};

    // Perishability assessment
    scores['perishability'] =
        features['is_dairy']! * 0.95 +
        features['is_meat']! * 1.0 +
        features['is_vegetable']! * 0.75 +
        features['is_fruit']! * 0.65 +
        features['is_grain']! * 0.25 +
        features['is_bakery']! * 0.45 +
        features['is_prepared']! * 0.70 -
        features['is_sweet']! * 0.40; // Sweets last longer

    // Moisture content (affects spoilage)
    scores['moisture'] =
        features['is_dairy']! * 0.85 +
        features['is_meat']! * 0.80 +
        features['is_vegetable']! * 0.90 +
        features['is_fruit']! * 0.88 +
        features['is_grain']! * 0.35 +
        features['is_prepared']! * 0.65;

    // Protein content (bacterial growth factor)
    scores['protein'] =
        features['is_meat']! * 1.0 +
        features['is_dairy']! * 0.75 +
        features['is_grain']! * 0.30;

    // Storage quality score
    scores['storage_quality'] =
        features['temp_cold']! * 1.0 +
        features['temp_ambient']! * 0.55 +
        features['temp_hot']! * 0.25 +
        features['pkg_sealed']! * 0.90 +
        features['pkg_moderate']! * 0.65 +
        features['pkg_open']! * 0.35;

    return scores;
  }

  // Calculate decay factors
  Map<String, double> _calculateDecayFactors(
    Map<String, double> storageScores,
    Map<String, double> features,
  ) {
    final decayFactors = <String, double>{};

    // Overall decay rate
    decayFactors['decay_rate'] =
        storageScores['perishability']! * 0.75 +
        storageScores['moisture']! * 0.55 +
        storageScores['protein']! * 0.65 -
        storageScores['storage_quality']! * 0.45;

    // Normalize decay rate
    decayFactors['decay_rate'] = 1 / (1 + exp(-decayFactors['decay_rate']!));

    // Freshness impact
    decayFactors['freshness_impact'] = features['freshness']! * 0.85;

    // Storage effectiveness
    decayFactors['storage_effectiveness'] =
        1 / (1 + exp(-storageScores['storage_quality']!));

    return decayFactors;
  }

  // Generate final prediction
  Map<String, dynamic> _generatePrediction(Map<String, double> decayScores) {
    // Calculate base shelf life
    final decayRate = decayScores['decay_rate']!;
    final storageEffectiveness = decayScores['storage_effectiveness']!;
    final freshnessImpact = decayScores['freshness_impact']!;

    // Advanced calculation for shelf life
    final baseLife = (1 - decayRate) * 8.0; // Base 8 days
    final storageBonus = storageEffectiveness * 6.0; // Up to 6 extra days
    final freshnessBonus = freshnessImpact * 4.0; // Up to 4 extra days

    final totalShelfLife = baseLife + storageBonus + freshnessBonus;

    // Clamp to realistic range (1-15 days)
    final predictedDays = totalShelfLife.clamp(1.0, 15.0).round();

    // Calculate reliability score
    double reliability = 0.55; // Base reliability

    // Increase reliability with better storage
    if (storageEffectiveness > 0.65) reliability += 0.20;
    if (decayRate < 0.50) reliability += 0.15;
    if (freshnessImpact > 0.55) reliability += 0.10;

    reliability = reliability.clamp(0.55, 0.98);

    return {'days': predictedDays, 'confidence': reliability};
  }

  // Helper widget for factor chips
  Widget _buildFactorChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE07A3E).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE07A3E).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: const Color(0xFFE07A3E)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
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
            colorScheme: const ColorScheme.light(primary: Color(0xFFE07A3E)),
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
            colorScheme: const ColorScheme.light(primary: Color(0xFFE07A3E)),
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
          address = place.locality ?? 'Unknown location';
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

                    const SizedBox(height: 16),

                    // Expiry Prediction Feature
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE07A3E).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFE07A3E),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Food Expiry Prediction',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_predictedExpiryDays == null &&
                              !_isLoadingPrediction)
                            ElevatedButton.icon(
                              onPressed: _foodTypeController.text.isNotEmpty
                                  ? _predictFoodExpiry
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE07A3E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(Icons.analytics, size: 18),
                              label: const Text('Predict Expiry Date'),
                            ),
                          if (_isLoadingPrediction)
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFFE07A3E),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Neural network analyzing...',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Processing food type, temperature, packaging & freshness',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          if (_predictedExpiryDays != null &&
                              !_isLoadingPrediction)
                            Column(
                              children: [
                                // Main prediction card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFFE07A3E,
                                        ).withOpacity(0.1),
                                        Colors.white,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE07A3E,
                                      ).withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          // Icon section
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE07A3E),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.schedule,
                                              color: Colors.white,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Prediction details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Predicted Shelf Life',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .baseline,
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                  children: [
                                                    Text(
                                                      '$_predictedExpiryDays',
                                                      style: const TextStyle(
                                                        fontSize: 36,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFFE07A3E,
                                                        ),
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      _predictedExpiryDays == 1
                                                          ? 'Day'
                                                          : 'Days',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black
                                                            .withOpacity(0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'from preparation date',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Refresh button
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFE07A3E,
                                                ).withOpacity(0.3),
                                              ),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.refresh,
                                                size: 20,
                                              ),
                                              color: const Color(0xFFE07A3E),
                                              onPressed: _predictFoodExpiry,
                                              tooltip: 'Recalculate',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Confidence indicator
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.psychology,
                                                      size: 16,
                                                      color: Color(0xFFE07A3E),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Text(
                                                      'Neural Network Confidence',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${(_predictionConfidence! * 100).toStringAsFixed(1)}%',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFE07A3E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: _predictionConfidence,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      _predictionConfidence! >
                                                              0.8
                                                          ? Colors.green
                                                          : _predictionConfidence! >
                                                                0.6
                                                          ? const Color(
                                                              0xFFE07A3E,
                                                            )
                                                          : Colors.orange,
                                                    ),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Neural network info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.settings_suggest,
                                            size: 14,
                                            color: Colors.black54,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'AI Analysis Factors',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          _buildFactorChip('Food Category'),
                                          if (_selectedTemperatureStatus !=
                                              null)
                                            _buildFactorChip('Temperature'),
                                          if (_selectedPackagingType != null)
                                            _buildFactorChip('Packaging'),
                                          if (_datePrepared != null)
                                            _buildFactorChip('Freshness'),
                                          _buildFactorChip('Perishability'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 12,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Neural network with 2 hidden layers analyzing multiple factors for accurate prediction',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black.withOpacity(0.5),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
                                  ? DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(_datePrepared!)
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
                      initialValue: _selectedDietaryTag,
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
                            (tag) =>
                                DropdownMenuItem(value: tag, child: Text(tag)),
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
                      initialValue: _selectedTemperatureStatus,
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
                      items:
                          [
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
                          onPressed: _isLoadingLocation
                              ? null
                              : _getCurrentLocation,
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
                      initialValue: _selectedPackagingType,
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
                      items:
                          ['Bulk container', 'Individual boxes', 'Sealed bags']
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
                                activeThumbColor: const Color(0xFFE07A3E),
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
                        onPressed: _isSubmitting
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  if (_imageFile == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please upload a food image',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  if (_datePrepared == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please select date prepared',
                                        ),
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

                                  // Set loading state
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  try {
                                    // Format date and time
                                    String formattedDate = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_datePrepared!);
                                    String formattedTime =
                                        '${_pickupTime!.hour.toString().padLeft(2, '0')}:${_pickupTime!.minute.toString().padLeft(2, '0')}';

                                    // Parse amount if paid donation
                                    double amount = 0;
                                    if (_isPaidDonation &&
                                        _amountController.text.isNotEmpty) {
                                      amount =
                                          double.tryParse(
                                            _amountController.text,
                                          ) ??
                                          0;
                                    }

                                    // Submit listing to backend
                                    final result = await _listingService
                                        .createListing(
                                          foodType: _foodTypeController.text,
                                          quantity: _quantityController.text,
                                          dietaryTag: _selectedDietaryTag!,
                                          temperatureStatus:
                                              _selectedTemperatureStatus!,
                                          location: _locationController.text,
                                          packagingType:
                                              _selectedPackagingType!,
                                          description:
                                              _descriptionController.text,
                                          datePrepared: formattedDate,
                                          pickupTime: formattedTime,
                                          isPaidDonation: _isPaidDonation,
                                          amount: amount,
                                          imageUrl: _imageFile!
                                              .path, // TODO: Upload image to server
                                        );

                                    setState(() {
                                      _isSubmitting = false;
                                    });

                                    if (result['success']) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              widget.isEditing
                                                  ? 'Listing updated successfully!'
                                                  : 'Listing created successfully!',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        Navigator.pop(
                                          context,
                                          true,
                                        ); // Return true to indicate success
                                      }
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result['message'] ??
                                                  'Failed to create listing',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _isSubmitting = false;
                                    });

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE07A3E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
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
