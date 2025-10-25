import 'package:flutter/material.dart';
import '../pages/ai_chatbot_page.dart';
import '../models/user.dart';
import '../pages/donor_home_page.dart';
import '../pages/receiver_home_page.dart';

class CommonFooter extends StatelessWidget {
  final int selectedIndex;
  final User? user; // Add user parameter

  const CommonFooter({
    super.key,
    this.selectedIndex = -1, // -1 means no item selected (for feature pages)
    this.user, // Optional user parameter
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Left: Notifications
              _buildNavBarItem(
                context: context,
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                isSelected: selectedIndex == 0,
                onTap: () {
                  // Navigate to notifications page or show notifications
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications coming soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              // Center: Home
              _buildNavBarItem(
                context: context,
                imagePath: 'assets/images/Home.png',
                icon: Icons.home,
                label: 'Home',
                isSelected: selectedIndex == 1,
                onTap: () {
                  // Navigate to the appropriate home page based on user type
                  if (user != null) {
                    if (user!.isDonor) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonorHomePage(user: user!),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    } else if (user!.isReceiver) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiverHomePage(user: user!),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    }
                  } else {
                    // Fallback: just pop to first route if no user provided
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
              // Right: AI Chatbot
              _buildNavBarItem(
                context: context,
                imagePath: 'assets/images/chatbot.png',
                icon: Icons.chat_bubble_outline,
                label: 'AI Chat',
                isSelected: selectedIndex == 2,
                onTap: () {
                  // Navigate to AI chatbot page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIChatbotPage(user: user),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required BuildContext context,
    IconData? icon,
    String? imagePath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  width: 28,
                  height: 28,
                  color: isSelected ? const Color(0xFFE07A3E) : Colors.grey,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      icon ?? Icons.home,
                      size: 28,
                      color: isSelected ? const Color(0xFFE07A3E) : Colors.grey,
                    );
                  },
                )
              else if (icon != null)
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? const Color(0xFFE07A3E) : Colors.grey,
                ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFFE07A3E) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
