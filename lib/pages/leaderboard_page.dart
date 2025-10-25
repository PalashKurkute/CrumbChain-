import 'package:flutter/material.dart';
import '../models/user.dart';

class LeaderboardPage extends StatefulWidget {
  final User? user;

  const LeaderboardPage({super.key, this.user});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // Sample leaderboard data
  final List<Map<String, dynamic>> _leaderboardData = [
    {'name': 'Aditya', 'points': 142, 'rank': 1, 'trend': 'up'},
    {'name': 'Palash', 'points': 100, 'rank': 2, 'trend': 'up'},
    {'name': 'Ankit', 'points': 99, 'rank': 3, 'trend': 'up'},
    {'name': 'Anuish', 'points': 95, 'rank': 4, 'trend': 'down'},
    {'name': 'Rahul', 'points': 87, 'rank': 5, 'trend': 'up'},
    {'name': 'Priya', 'points': 82, 'rank': 6, 'trend': 'down'},
    {'name': 'Sneha', 'points': 78, 'rank': 7, 'trend': 'up'},
    {'name': 'Rohan', 'points': 71, 'rank': 8, 'trend': 'up'},
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
                    points: _leaderboardData[1]['points'],
                    height: 90,
                  ),
                  // 1st Place
                  _buildPodiumItem(
                    rank: 1,
                    name: _leaderboardData[0]['name'],
                    points: _leaderboardData[0]['points'],
                    height: 135,
                  ),
                  // 3rd Place
                  _buildPodiumItem(
                    rank: 3,
                    name: _leaderboardData[2]['name'],
                    points: _leaderboardData[2]['points'],
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
                          points: item['points'],
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
    required int points,
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
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFFD700),
                      size: 26,
                    ),
                  ),
                // Name and points badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
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
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$points Pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
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
    required int points,
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
          // Points
          Text(
            '$points',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE07A3E),
            ),
          ),
        ],
      ),
    );
  }
}
