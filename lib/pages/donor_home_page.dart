import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class DonorHomePage extends StatefulWidget {
  final User user;

  const DonorHomePage({super.key, required this.user});

  @override
  State<DonorHomePage> createState() => _DonorHomePageState();
}

class _DonorHomePageState extends State<DonorHomePage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEFDD),
      appBar: AppBar(
        title: const Text('Donor Dashboard'),
        backgroundColor: const Color(0xFFE07A3E),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${widget.user.fullName}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Email: ${widget.user.email}',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),

              // Donor specific content
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  children: [
                    _buildDashboardCard(
                      icon: Icons.add_circle,
                      title: 'Donate Food',
                      color: const Color(0xFFE07A3E),
                      onTap: () {
                        // TODO: Navigate to donate food page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Donate Food - Coming Soon'),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.history,
                      title: 'My Donations',
                      color: const Color(0xFF4CAF50),
                      onTap: () {
                        // TODO: Navigate to donation history
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Donation History - Coming Soon'),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.location_on,
                      title: 'Pickup Points',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        // TODO: Navigate to pickup points
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pickup Points - Coming Soon'),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      icon: Icons.settings,
                      title: 'Settings',
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                        // TODO: Navigate to settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Settings - Coming Soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
