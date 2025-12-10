import 'package:flutter/material.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';

class CreateRequirementsPage extends StatefulWidget {
  final User? user;
  final bool isEditing;

  const CreateRequirementsPage({
    super.key,
    this.user,
    this.isEditing = false,
  });

  @override
  State<CreateRequirementsPage> createState() => _CreateRequirementsPageState();
}

class _CreateRequirementsPageState extends State<CreateRequirementsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _operatingHoursController = TextEditingController();
  final _crowdSizeController = TextEditingController();
  
  // Dropdowns and selections
  String? _selectedFoodTag;
  String? _selectedCategory;
  
  // Time selections
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  
  // Loading state for submission
  bool _isSubmitting = false;

  @override
  void dispose() {
    _operatingHoursController.dispose();
    _crowdSizeController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
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
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _updateOperatingHours();
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 18, minute: 0),
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
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _updateOperatingHours();
      });
    }
  }

  void _updateOperatingHours() {
    if (_startTime != null && _endTime != null) {
      _operatingHoursController.text =
          '${_startTime!.format(context)} - ${_endTime!.format(context)}';
    } else if (_startTime != null) {
      _operatingHoursController.text = '${_startTime!.format(context)} - ';
    } else if (_endTime != null) {
      _operatingHoursController.text = ' - ${_endTime!.format(context)}';
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
                      'assets/images/requirements.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.list_alt,
                          size: 48,
                          color: Colors.black87,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    widget.isEditing
                        ? 'Edit Requirements'
                        : 'Create Requirements List',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Specify your food requirements to receive donations',
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
                    // 1. Operating Hours
                    const Text(
                      '1. Operating Hours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Specify when you can receive food donations',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectStartTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCEEDD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _startTime != null
                                            ? _startTime!.format(context)
                                            : 'Select time',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _startTime != null
                                              ? Colors.black87
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Time',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _selectEndTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCEEDD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _endTime != null
                                            ? _endTime!.format(context)
                                            : 'Select time',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _endTime != null
                                              ? Colors.black87
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 2. Preferred Food Tag
                    const Text(
                      '2. Preferred Food Tag',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedFoodTag,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.restaurant),
                      ),
                      hint: const Text('Select preferred food type'),
                      items: ['Veg', 'Non-Veg', 'Jain', 'Halal', 'Any']
                          .map(
                            (tag) => DropdownMenuItem(
                              value: tag,
                              child: Text(tag),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFoodTag = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a food tag';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 3. Preferred Category
                    const Text(
                      '3. Preferred Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      hint: const Text('Select preferred category'),
                      items: [
                        'Cooked Food',
                        'Raw Ingredients',
                        'Packaged Food',
                        'Fruits & Vegetables',
                        'Dairy Products',
                        'Bakery Items',
                        'Any',
                      ]
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // 4. Crowd Size
                    const Text(
                      '4. Crowd of People to be Fed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Approximate number of people',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _crowdSizeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g., 50 people, 100-150 people',
                        filled: true,
                        fillColor: const Color(0xFFFCEEDD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.groups),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter crowd size';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isSubmitting = true;
                                  });

                                  // TODO: Submit requirements to backend
                                  Future.delayed(
                                    const Duration(seconds: 1),
                                    () {
                                      setState(() {
                                        _isSubmitting = false;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            widget.isEditing
                                                ? 'Requirements updated successfully!'
                                                : 'Requirements created successfully!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    },
                                  );
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
                                    ? 'Update Requirements'
                                    : 'Create Requirements',
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
