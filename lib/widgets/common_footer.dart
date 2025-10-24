import 'package:flutter/material.dart';

class CommonFooter extends StatelessWidget {
  final int selectedIndex;

  const CommonFooter({
    super.key,
    this.selectedIndex = -1, // -1 means no item selected (for feature pages)
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
                  // Navigate back to home, removing all pages in between
                  Navigator.of(context).popUntil((route) => route.isFirst);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI Chat coming soon!'),
                      duration: Duration(seconds: 1),
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
