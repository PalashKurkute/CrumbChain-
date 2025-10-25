import 'package:flutter/material.dart';
import '../models/user.dart';

class LeaderboardPage extends StatefulWidget {
  final User? user;

  const LeaderboardPage({super.key, this.user});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // Sample leaderboard data with ratings out of 5
  final List<Map<String, dynamic>> _leaderboardData = [
    {'name': 'Aditya', 'rating': 4.9, 'rank': 1, 'trend': 'up', 'reviews': 45},
    {'name': 'Palash', 'rating': 4.8, 'rank': 2, 'trend': 'up', 'reviews': 38},
    {'name': 'Ankit', 'rating': 4.7, 'rank': 3, 'trend': 'up', 'reviews': 42},
    {
      'name': 'Anuish',
      'rating': 4.6,
      'rank': 4,
      'trend': 'down',
      'reviews': 35,
    },
    {'name': 'Rahul', 'rating': 4.5, 'rank': 5, 'trend': 'up', 'reviews': 30},
    {'name': 'Priya', 'rating': 4.4, 'rank': 6, 'trend': 'down', 'reviews': 28},
    {'name': 'Sneha', 'rating': 4.3, 'rank': 7, 'trend': 'up', 'reviews': 25},
    {'name': 'Rohan', 'rating': 4.2, 'rank': 8, 'trend': 'up', 'reviews': 22},
  ];

  Color _getPodiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFE74C3C); // Red for 1st
      case 2:
        return const Color(0xFFF39C12); // Orange for 2nd
      case 3:
        return const Color(0xFF3498DB); // Blue for 3rd
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Leaderboard',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Podium Section
          SizedBox(
            height: 250,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd Place
                  _buildPodiumItem(
                    rank: 2,
                    name: _leaderboardData[1]['name'],
                    rating: _leaderboardData[1]['rating'],
                    reviews: _leaderboardData[1]['reviews'],
                    height: 90,
                  ),
                  // 1st Place
                  _buildPodiumItem(
                    rank: 1,
                    name: _leaderboardData[0]['name'],
                    rating: _leaderboardData[0]['rating'],
                    reviews: _leaderboardData[0]['reviews'],
                    height: 135,
                  ),
                  // 3rd Place
                  _buildPodiumItem(
                    rank: 3,
                    name: _leaderboardData[2]['name'],
                    rating: _leaderboardData[2]['rating'],
                    reviews: _leaderboardData[2]['reviews'],
                    height: 70,
                  ),
                ],
              ),
            ),
          ),

          // List Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Divider with dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _leaderboardData.length,
                      itemBuilder: (context, index) {
                        final item = _leaderboardData[index];
                        return _buildLeaderboardItem(
                          rank: item['rank'],
                          name: item['name'],
                          rating: item['rating'],
                          reviews: item['reviews'],
                          trend: item['trend'],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required int rank,
    required String name,
    required double rating,
    required int reviews,
    required double height,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Crown for 1st place
                if (rank == 1)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                  ),
                // Name and rating badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPodiumColor(rank),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 9),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '($reviews)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Podium
                Container(
                  width: double.infinity,
                  height: height,
                  decoration: BoxDecoration(
                    color: _getPodiumColor(rank).withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: _getPodiumColor(rank),
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required String name,
    required double rating,
    required int reviews,
    required String trend,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Trend indicator
          Icon(
            trend == 'up' ? Icons.arrow_upward : Icons.arrow_downward,
            color: trend == 'up' ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 16),
          // Rank
          SizedBox(
            width: 30,
            child: Text(
              '$rank',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          // Name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          // Rating and reviews
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFE07A3E), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE07A3E),
                    ),
                  ),
                ],
              ),
              Text(
                '$reviews reviews',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
