import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/common_footer.dart';

class RewardsPage extends StatefulWidget {
  final User? user;

  const RewardsPage({super.key, this.user});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('Please log in to view rewards'),
        ),
      );
    }

    final rewardPoints = widget.user!.rewardPoints;
    final totalOrders = widget.user!.totalOrdersReceived;

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
                      'assets/images/rewards.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.stars,
                          size: 48,
                          color: Colors.black87,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'My Rewards',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Earn and redeem points for your community impact',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
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
                  colors: [Color(0xFF20B2AA), Color(0xFF1E90FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF20B2AA).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Reward Points',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$rewardPoints',
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
                    child: Text(
                      '$totalOrders orders received',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
                      icon: Icons.shopping_bag,
                      label: 'Orders',
                      value: totalOrders.toString(),
                      color: const Color(0xFFE07A3E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.trending_up,
                      label: 'Avg Points',
                      value: totalOrders > 0
                          ? (rewardPoints / totalOrders).toStringAsFixed(1)
                          : '0',
                      color: const Color(0xFF20B2AA),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Redeem Rewards Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Redeem Rewards',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exchange your points for exciting rewards and benefits',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRedeemCard(
                    title: '₹50 Food Voucher',
                    points: 500,
                    description: 'Redeem at partner restaurants',
                    icon: Icons.restaurant_menu,
                    color: const Color(0xFFE07A3E),
                    canRedeem: rewardPoints >= 500,
                  ),
                  _buildRedeemCard(
                    title: '₹100 Grocery Coupon',
                    points: 1000,
                    description: 'Use at local grocery stores',
                    icon: Icons.shopping_cart,
                    color: const Color(0xFF20B2AA),
                    canRedeem: rewardPoints >= 1000,
                  ),
                  _buildRedeemCard(
                    title: 'Priority Access',
                    points: 750,
                    description: 'Get priority for urgent orders',
                    icon: Icons.bolt,
                    color: const Color(0xFFFFD700),
                    canRedeem: rewardPoints >= 750,
                  ),
                  _buildRedeemCard(
                    title: 'Community Badge',
                    points: 1500,
                    description: 'Special recognition in the app',
                    icon: Icons.verified,
                    color: const Color(0xFF9C27B0),
                    canRedeem: rewardPoints >= 1500,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // How It Works Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to Earn Points',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHowItWorksItem(
                    icon: Icons.check_circle,
                    title: 'Receive Food Orders',
                    description: 'Earn points when you successfully receive donated food items',
                    points: '+10 base points',
                  ),
                  _buildHowItWorksItem(
                    icon: Icons.restaurant,
                    title: 'Meal Type Bonus',
                    description: 'Get extra points based on the type of meal received',
                    points: '+3 to +7 points',
                  ),
                  _buildHowItWorksItem(
                    icon: Icons.scale,
                    title: 'Quantity Bonus',
                    description: 'Larger quantities mean more bonus points',
                    points: 'Up to +20 points',
                  ),
                  _buildHowItWorksItem(
                    icon: Icons.speed,
                    title: 'Urgency Bonus',
                    description: 'Receive urgent items to earn extra rewards',
                    points: '+3 to +10 points',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Rewards Tiers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reward Tiers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTierCard(
                    title: '🥉 Bronze',
                    range: '0 - 99 points',
                    benefits: 'Getting started!',
                    isActive: rewardPoints < 100,
                  ),
                  _buildTierCard(
                    title: '🥈 Silver',
                    range: '100 - 499 points',
                    benefits: 'Regular recipient',
                    isActive: rewardPoints >= 100 && rewardPoints < 500,
                  ),
                  _buildTierCard(
                    title: '🥇 Gold',
                    range: '500 - 999 points',
                    benefits: 'Community champion',
                    isActive: rewardPoints >= 500 && rewardPoints < 1000,
                  ),
                  _buildTierCard(
                    title: '💎 Diamond',
                    range: '1000+ points',
                    benefits: 'Impact maker',
                    isActive: rewardPoints >= 1000,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: CommonFooter(
        user: widget.user,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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

  Widget _buildRedeemCard({
    required String title,
    required int points,
    required String description,
    required IconData icon,
    required Color color,
    required bool canRedeem,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canRedeem ? color.withOpacity(0.3) : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                    fontWeight: FontWeight.w600,
                    color: canRedeem ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$points points',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canRedeem ? () => _showRedeemDialog(title, points) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canRedeem ? color : Colors.grey.shade300,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: canRedeem ? 2 : 0,
            ),
            child: Text(
              canRedeem ? 'Redeem' : 'Locked',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog(String title, int points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Color(0xFFE07A3E)),
            SizedBox(width: 8),
            Text('Redeem Reward'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to redeem:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEEDD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE07A3E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cost: $points points',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will deduct $points points from your balance.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRedemption(title, points);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20B2AA),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _processRedemption(String title, int points) {
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reward Redeemed!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Your $title will be sent to your registered email',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // TODO: In a real app, this would call a backend API to process the redemption
    // For now, we just show the success message
  }

  Widget _buildHowItWorksItem({
    required IconData icon,
    required String title,
    required String description,
    required String points,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE07A3E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFE07A3E), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF20B2AA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String range,
    required String benefits,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF20B2AA).withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF20B2AA) : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: const Color(0xFF20B2AA).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive ? const Color(0xFF20B2AA) : Colors.black87,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF20B2AA),
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  benefits,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? const Color(0xFF20B2AA) : Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
