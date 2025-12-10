import 'package:flutter/material.dart';
import '../models/user.dart';

class SettingsPage extends StatefulWidget {
  final User? user;

  const SettingsPage({super.key, this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedTheme = 'Light';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFE07A3E),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appearance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Theme', style: TextStyle(fontSize: 16)),
                      DropdownButton<String>(
                        value: _selectedTheme,
                        items: const [
                          DropdownMenuItem(
                            value: 'Light',
                            child: Row(
                              children: [
                                Icon(Icons.light_mode, size: 20),
                                SizedBox(width: 8),
                                Text('Light'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Dark',
                            child: Row(
                              children: [
                                Icon(Icons.dark_mode, size: 20),
                                SizedBox(width: 8),
                                Text('Dark'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'System',
                            child: Row(
                              children: [
                                Icon(Icons.brightness_auto, size: 20),
                                SizedBox(width: 8),
                                Text('System'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedTheme = newValue!;
                          });
                          // TODO: Implement theme change logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Theme changed to $_selectedTheme'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notifications Settings
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Push Notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement notification toggle
                      },
                      activeThumbColor: const Color(0xFFE07A3E),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    title: const Text('Email Notifications'),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // TODO: Implement email notification toggle
                      },
                      activeThumbColor: const Color(0xFFE07A3E),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    title: const Text('Privacy Policy'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      // TODO: Navigate to privacy policy
                    },
                  ),
                  ListTile(
                    title: const Text('Terms of Service'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    contentPadding: EdgeInsets.zero,
                    onTap: () {
                      // TODO: Navigate to terms of service
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
