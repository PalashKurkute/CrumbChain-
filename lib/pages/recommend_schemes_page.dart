import 'package:flutter/material.dart';
import '../widgets/common_footer.dart';
import '../models/user.dart';

class RecommendSchemesPage extends StatefulWidget {
  final User? user;

  const RecommendSchemesPage({super.key, this.user});

  @override
  State<RecommendSchemesPage> createState() => _RecommendSchemesPageState();
}

class _RecommendSchemesPageState extends State<RecommendSchemesPage> {
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
                      'assets/images/government_schemes.png',
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.recommend,
                          size: 48,
                          color: Colors.black87,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Recommend Schemes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Discover government schemes and programs that support food donation and waste management',
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

            // Body Content - Schemes
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSchemeCard(
                    title: 'PM POSHAN Scheme',
                    description:
                        'Mid-day meal program supporting nutritional needs of school children',
                    benefits: 'Tax benefits, Recognition certificate',
                    icon: Icons.school,
                  ),

                  const SizedBox(height: 12),

                  _buildSchemeCard(
                    title: 'Food Safety and Standards Authority',
                    description:
                        'Guidelines for safe food donation and surplus food distribution',
                    benefits: 'Legal protection, Quality assurance',
                    icon: Icons.verified,
                  ),

                  const SizedBox(height: 12),

                  _buildSchemeCard(
                    title: 'Swachh Bharat Mission',
                    description:
                        'Composting and waste management initiatives for organic waste',
                    benefits: 'Subsidy support, Training programs',
                    icon: Icons.cleaning_services,
                  ),

                  const SizedBox(height: 12),

                  _buildSchemeCard(
                    title: 'Zero Hunger Initiative',
                    description:
                        'Platform connecting food donors with NGOs and beneficiaries',
                    benefits: 'Network access, Impact tracking',
                    icon: Icons.favorite,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CommonFooter(user: widget.user),
    );
  }

  Widget _buildSchemeCard({
    required String title,
    required String description,
    required String benefits,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEDD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE07A3E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, size: 16, color: Color(0xFFE07A3E)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    benefits,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
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
