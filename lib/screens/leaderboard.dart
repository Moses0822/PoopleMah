import 'package:flutter/material.dart';
import '../db_helper.dart'; // Import DBHelper directly
import '../Theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final String currentUserId;
  const LeaderboardScreen({super.key, required this.currentUserId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> leaderboard = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    try {
      final dbHelper = DBHelper();
      
      // First, refresh all streaks to ensure they're up to date
      await refreshAllStreaks();
      
      // Get leaderboard data with current streaks
      final data = await getLeaderboardForUser(widget.currentUserId);
      setState(() {
        leaderboard = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading leaderboard: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to refresh all user streaks
  Future<void> refreshAllStreaks() async {
    final dbHelper = DBHelper();
    final db = await dbHelper.database;
    
    // Get all users who have checkins
    final users = await db.rawQuery('''
      SELECT DISTINCT userId FROM checkins
    ''');
    
    for (var user in users) {
      final userId = user['userId'] as String;
      final calculatedStreak = await dbHelper.getCheckinStreakFixed(userId);
      
      // Update or insert streak in stats table
      final existingStats = await db.query('stats', where: 'userId = ?', whereArgs: [userId]);
      
      if (existingStats.isNotEmpty) {
        await db.update(
          'stats',
          {'streak': calculatedStreak},
          where: 'userId = ?',
          whereArgs: [userId],
        );
      } else {
        await db.insert('stats', {
          'userId': userId,
          'streak': calculatedStreak,
          'totalPoops': 0,
        });
      }
    }
  }

  // Method to get leaderboard data
  Future<List<Map<String, dynamic>>> getLeaderboardForUser(String userId) async {
    final db = await DBHelper().database;
    
    // Get all friends and their streak data, including the current user
    final result = await db.rawQuery('''
      SELECT DISTINCT u.id, u.username, COALESCE(s.streak, 0) as points
      FROM users u
      LEFT JOIN stats s ON u.id = s.userId
      WHERE u.id = ? 
      OR u.id IN (
        SELECT CASE 
          WHEN f.userId = ? THEN f.friendId 
          ELSE f.userId 
        END as friendId
        FROM friends f 
        WHERE (f.userId = ? OR f.friendId = ?) 
        AND f.status = 'accepted'
      )
      ORDER BY COALESCE(s.streak, 0) DESC, u.username ASC
    ''', [userId, userId, userId, userId]);
    
    print("Leaderboard query result: $result");
    return result;
  }

  Widget _buildPodiumAvatar(Map<String, dynamic> user, int position) {
    final isCurrentUser = user['id'] == widget.currentUserId;
    final colors = [
      const Color(0xFFFFD700), // 1st
      const Color(0xFFC0C0C0), // 2nd
      const Color(0xFFCD7F32), // 3rd
    ];

    final borderColors = [
      const Color(0xFFB8860B),
      const Color(0xFF999999),
      const Color(0xFFA0522D),
    ];

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: position == 0 ? 80 : 65,
            height: position == 0 ? 80 : 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors[position],
              border: Border.all(
                color: borderColors[position],
                width: 3,
              ),
              boxShadow: AppTheme.strongCartoonShadow,
            ),
            child: CircleAvatar(
              radius: position == 0 ? 36 : 29,
              backgroundColor: AppTheme.cardBackground,
              backgroundImage: user['avatar'] != null
                  ? NetworkImage(user['avatar'])
                  : null,
              child: user['avatar'] == null
                  ? Text(
                      user['username']?.substring(0, 1).toUpperCase() ?? '?',
                      style: AppTheme.cartoonTitle.copyWith(
                        fontSize: position == 0 ? 24 : 20,
                        color: AppTheme.brownPrimary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            constraints: const BoxConstraints(maxWidth: 100),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor, width: 2),
            ),
            child: Text(
              user['username'] ?? 'Unknown',
              style: AppTheme.cartoonBody.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: position == 0 ? 13 : 12,
                color: isCurrentUser ? AppTheme.brownPrimary : AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${user['points'] ?? 0} day streak',
            style: AppTheme.cartoonCaption.copyWith(
              fontSize: position == 0 ? 12 : 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    if (leaderboard.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppTheme.cartoonCard(
          backgroundColor: AppTheme.friendlyGreen,
          borderColor: AppTheme.softGreen,
          child: Column(
            children: [
              Text(
                '${AppTheme.funnyEmojis['happy']} No friends ranked yet!',
                style: AppTheme.cartoonTitle.copyWith(
                  color: AppTheme.brownPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add more friends to start competing on the leaderboard!',
                style: AppTheme.cartoonBody.copyWith(
                  color: AppTheme.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final topUsers =
        leaderboard.length >= 3 ? leaderboard.take(3).toList() : leaderboard;

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topUsers.length > 1) _buildPodiumAvatar(topUsers[1], 1),
          if (topUsers.isNotEmpty) _buildPodiumAvatar(topUsers[0], 0),
          if (topUsers.length > 2) _buildPodiumAvatar(topUsers[2], 2),
        ],
      ),
    );
  }

  Widget _buildRankedList() {
    final rankingUsers =
        leaderboard.length > 3 ? leaderboard.skip(3).toList() : [];

    if (rankingUsers.isEmpty && leaderboard.length <= 3) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: AppTheme.cartoonCard(
          backgroundColor: AppTheme.friendlyGreen,
          borderColor: AppTheme.softGreen,
          child: Column(
            children: [
              Text(
                '${AppTheme.funnyEmojis['happy']} Ready to compete?',
                style: AppTheme.cartoonTitle.copyWith(
                  color: AppTheme.brownPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add more friends to see who\'s the ultimate poop champion!',
                style: AppTheme.cartoonBody.copyWith(
                  color: AppTheme.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rankingUsers.length,
      itemBuilder: (context, index) {
        final entry = rankingUsers[index];
        final position = index + 4;
        final isCurrentUser = entry['id'] == widget.currentUserId;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: AppTheme.cartoonCard(
            backgroundColor:
                isCurrentUser ? AppTheme.softPink : AppTheme.cardBackground,
            borderColor:
                isCurrentUser ? AppTheme.brownPrimary : AppTheme.borderColor,
            borderWidth: isCurrentUser ? 3 : 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.lightBrown,
                  backgroundImage: entry['avatar'] != null
                      ? NetworkImage(entry['avatar'])
                      : null,
                  child: entry['avatar'] == null
                      ? Text(
                          entry['username']?.substring(0, 1).toUpperCase() ??
                              '?',
                          style: AppTheme.cartoonBody.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['username'] ?? 'Unknown',
                        style: AppTheme.cartoonBody.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isCurrentUser
                              ? AppTheme.brownPrimary
                              : AppTheme.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        '${AppTheme.funnyEmojis['streak']} ${entry['points'] ?? 0} day streak',
                        style: AppTheme.cartoonCaption.copyWith(
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeAccent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.brownPrimary, width: 2),
                  ),
                  child: Text(
                    '#$position',
                    style: AppTheme.cartoonBody.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFriendsLeaderboard() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brownPrimary),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildPodium(),
          const SizedBox(height: 20),
          _buildRankedList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.themeData,
      child: Scaffold(
        backgroundColor: AppTheme.creamBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.creamBackground,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppTheme.cartoonIconButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
              backgroundColor: AppTheme.cardBackground,
              size: 40,
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Leaderboard',
                  style: AppTheme.cartoonTitle.copyWith(
                    fontSize: 22,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                AppTheme.funnyEmojis['poop']!,
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: _buildFriendsLeaderboard(),
      ),
    );
  }
}