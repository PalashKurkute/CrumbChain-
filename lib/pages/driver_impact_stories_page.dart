import 'package:flutter/material.dart';
import '../models/user.dart';

class DriverImpactStoriesPage extends StatelessWidget {
  final User user;

  const DriverImpactStoriesPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Logo
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.volunteer_activism,
                      size: 80,
                      color: Color(0xFFE07A3E),
                    );
                  },
                ),
              ),

              // Cream header band
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFFCEEDD),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Impact Stories',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real stories of how drivers like you are making a difference',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Impact Statistics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE07A3E), Color(0xFFFF8C42)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE07A3E).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Your Impact This Month',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ImpactStat(
                            icon: Icons.restaurant,
                            value: '127',
                            label: 'Meals\nDelivered',
                          ),
                          _ImpactStat(
                            icon: Icons.groups,
                            value: '89',
                            label: 'Families\nHelped',
                          ),
                          _ImpactStat(
                            icon: Icons.route,
                            value: '342',
                            label: 'Kilometers\nDriven',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Stories Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Stories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStoryCard(
                      name: 'Rajesh Kumar',
                      location: 'Mumbai',
                      story:
                          'In my 6 months as a CrumbChain driver, I\'ve delivered over 500 meals. The best part? Seeing the smiles on people\'s faces when I deliver fresh food. Last week, I delivered to an old age home - it was the most rewarding delivery ever. This isn\'t just a job, it\'s a way to give back to my community.',
                      deliveries: 523,
                      color: const Color(0xFFE07A3E),
                      icon: Icons.sentiment_very_satisfied,
                    ),
                    const SizedBox(height: 16),
                    _buildStoryCard(
                      name: 'Priya Sharma',
                      location: 'Delhi',
                      story:
                          'Being a CrumbChain driver has changed my perspective. Every delivery reminds me that we\'re part of something bigger - fighting food waste while helping those in need. The flexible hours let me balance my studies, and the rewards program helps with fuel costs. It\'s a win-win!',
                      deliveries: 347,
                      color: const Color(0xFF20B2AA),
                      icon: Icons.school,
                    ),
                    const SizedBox(height: 16),
                    _buildStoryCard(
                      name: 'Mohammed Ali',
                      location: 'Bangalore',
                      story:
                          'During the monsoon season, I made it my mission to deliver every order, no matter the weather. One evening, I delivered food to a children\'s shelter just before dinner time. The caretaker told me the kids had been waiting eagerly. That moment made every rainy ride worth it.',
                      deliveries: 412,
                      color: const Color(0xFF9C27B0),
                      icon: Icons.cloud,
                    ),
                    const SizedBox(height: 16),
                    _buildStoryCard(
                      name: 'Anita Desai',
                      location: 'Pune',
                      story:
                          'As a retired teacher, I wanted to stay active and contribute to society. CrumbChain gave me that opportunity. I\'ve made so many connections - from restaurant owners to families I deliver to. It\'s not about the earnings; it\'s about the relationships and knowing I\'m making a difference.',
                      deliveries: 289,
                      color: const Color(0xFF4CAF50),
                      icon: Icons.favorite,
                    ),
                    const SizedBox(height: 16),
                    _buildStoryCard(
                      name: 'Vikram Singh',
                      location: 'Hyderabad',
                      story:
                          'Started as a part-time driver, now I\'m Gold tier! The best delivery? A birthday cake that would have been wasted to a family celebrating their daughter\'s birthday. They couldn\'t afford a cake, and seeing their joy was priceless. CrumbChain isn\'t just about food delivery - it\'s about delivering happiness.',
                      deliveries: 651,
                      color: const Color(0xFFFFD700),
                      icon: Icons.cake,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Call to Action
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEEDD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE07A3E).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      size: 48,
                      color: Color(0xFFE07A3E),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Share Your Story',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Have a memorable delivery experience? Share your story with the CrumbChain community and inspire others!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Story submission - Coming soon!'),
                            backgroundColor: Color(0xFFE07A3E),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Submit Your Story'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE07A3E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildStoryCard({
    required String name,
    required String location,
    required String story,
    required int deliveries,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '$deliveries',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            story,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
