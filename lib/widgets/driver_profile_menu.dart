import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../main.dart';
import '../pages/change_password_page.dart';
import '../pages/settings_page.dart';
import '../pages/how_it_works_page.dart';

class DriverProfileMenu {
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
                  return const Icon(Icons.info_outline, size: 24, color: Color(0xFFE07A3E));
                },
              ),
              title: const Text('How It Works'),
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
            ListTile(
              leading: Image.asset(
                'assets/images/logout.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.logout, size: 24, color: Colors.red);
                },
              ),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
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
}
