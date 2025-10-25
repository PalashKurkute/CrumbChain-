import 'package:flutter/material.dart';
import '../models/user.dart';

class DriverPerksRewardsPage extends StatefulWidget {
  final User user;

  const DriverPerksRewardsPage({super.key, required this.user});

  @override
  State<DriverPerksRewardsPage> createState() => _DriverPerksRewardsPageState();
}

class _DriverPerksRewardsPageState extends State<DriverPerksRewardsPage> {
  // Mock data - in real app, fetch from backend
  final int deliveryPoints = 450;
  final int totalDeliveries = 23;
  final int currentLevel = 3;
  final String currentTier = 'Gold Driver';

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
                      'Perks & Rewards',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Earn rewards and unlock exclusive driver benefits',
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

              // Points Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  children: [
                    const Text(
                      'Your Driver Points',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$deliveryPoints',
                      style: const TextStyle(
                        fontSize: 56,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '$totalDeliveries completed deliveries',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Stats Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.stars,
                        label: 'Current Tier',
                        value: currentTier,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.trending_up,
                        label: 'Level',
                        value: 'Level $currentLevel',
                        color: const Color(0xFF20B2AA),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Perks Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Active Perks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPerkCard(
                      icon: Icons.local_gas_station,
                      title: 'Fuel Vouchers',
                      description: 'Earn ₹500 fuel voucher every 50 deliveries',
                      progress: totalDeliveries % 50,
                      total: 50,
                      color: const Color(0xFFE07A3E),
                    ),
                    const SizedBox(height: 12),
                    _buildPerkCard(
                      icon: Icons.phone_android,
                      title: 'Mobile Recharge',
                      description: 'Get ₹200 mobile recharge every 30 deliveries',
                      progress: totalDeliveries % 30,
                      total: 30,
                      color: const Color(0xFF20B2AA),
                    ),
                    const SizedBox(height: 12),
                    _buildPerkCard(
                      icon: Icons.restaurant,
                      title: 'Free Meal Voucher',
                      description: 'Claim a free meal after 10 deliveries',
                      progress: totalDeliveries % 10,
                      total: 10,
                      color: const Color(0xFF9C27B0),
                    ),
                    const SizedBox(height: 12),
                    _buildPerkCard(
                      icon: Icons.health_and_safety,
                      title: 'Health Insurance',
                      description: 'Unlock basic health insurance at 100 deliveries',
                      progress: totalDeliveries,
                      total: 100,
                      color: const Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Tier Benefits Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Driver Tiers',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTierCard(
                      tier: 'Bronze Driver',
                      range: '0-100 points',
                      benefits: [
                        'Basic delivery dashboard',
                        'Standard support',
                        'Monthly performance report',
                      ],
                      color: const Color(0xFFCD7F32),
                      isActive: currentLevel == 1,
                    ),
                    const SizedBox(height: 12),
                    _buildTierCard(
                      tier: 'Silver Driver',
                      range: '101-300 points',
                      benefits: [
                        'Priority order access',
                        '5% bonus on earnings',
                        'Dedicated support line',
                      ],
                      color: const Color(0xFFC0C0C0),
                      isActive: currentLevel == 2,
                    ),
                    const SizedBox(height: 12),
                    _buildTierCard(
                      tier: 'Gold Driver',
                      range: '301-600 points',
                      benefits: [
                        'First pick on premium deliveries',
                        '10% bonus on earnings',
                        'Free vehicle maintenance (yearly)',
                        'VIP support',
                      ],
                      color: const Color(0xFFFFD700),
                      isActive: currentLevel == 3,
                    ),
                    const SizedBox(height: 12),
                    _buildTierCard(
                      tier: 'Platinum Driver',
                      range: '600+ points',
                      benefits: [
                        'Guaranteed high-value orders',
                        '15% bonus on earnings',
                        'Premium health insurance',
                        'Exclusive brand partnerships',
                        'Annual recognition award',
                      ],
                      color: const Color(0xFFE5E4E2),
                      isActive: currentLevel == 4,
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkCard({
    required IconData icon,
    required String title,
    required String description,
    required int progress,
    required int total,
    required Color color,
  }) {
    final percentage = (progress / total).clamp(0.0, 1.0);

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: color.withOpacity(0.1),
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$progress/$total',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String tier,
    required String range,
    required List<String> benefits,
    required Color color,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade300,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive ? color : Colors.black87,
                      ),
                    ),
                    Text(
                      range,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
