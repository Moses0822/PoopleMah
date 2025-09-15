import '../db_helper.dart';

class FriendService {
  final DBHelper _dbHelper = DBHelper();

  /// Get leaderboard (current user + friends), with real streak calculation
  Future<List<Map<String, dynamic>>> getLeaderboardForUser(String userId) async {
    final db = await _dbHelper.database;

    // 1. Get all users (self + friends)
    final users = await db.rawQuery('''
      SELECT DISTINCT u.id, u.username
      FROM users u
      WHERE u.id = ? 
         OR u.id IN (
           SELECT f.friendId FROM friends f WHERE f.userId = ? AND f.status = 'accepted'
           UNION
           SELECT f.userId FROM friends f WHERE f.friendId = ? AND f.status = 'accepted'
         )
    ''', [userId, userId, userId]);

    List<Map<String, dynamic>> leaderboard = [];

    // 2. For each user, calculate streak & totalPoops
    for (var u in users) {
      final uid = u['id'] as String;
      final username = u['username'] as String? ?? 'Unknown';

      final streak = await _calculateStreak(uid);
      final totalPoops = await _calculateTotalPoops(uid);

      leaderboard.add({
        'id': uid,
        'username': username,
        'streak': streak,
        'totalPoops': totalPoops,
      });
    }

    // 3. Sort: streak DESC, then totalPoops DESC
    leaderboard.sort((a, b) {
      final streakA = a['streak'] as int;
      final streakB = b['streak'] as int;
      if (streakA != streakB) return streakB.compareTo(streakA);
      return (b['totalPoops'] as int).compareTo(a['totalPoops'] as int);
    });

    return leaderboard;
  }

  /// Calculate true consecutive streak from checkins
  Future<int> _calculateStreak(String userId) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery('''
      SELECT DISTINCT dateOnly 
      FROM checkins 
      WHERE userId = ? 
      ORDER BY dateOnly DESC
    ''', [userId]);

    if (results.isEmpty) return 0;

    int streak = 1;
    DateTime? prev = DateTime.parse(results.first['dateOnly'] as String);

    for (int i = 1; i < results.length; i++) {
      final current = DateTime.parse(results[i]['dateOnly'] as String);
      if (prev!.difference(current).inDays == 1) {
        streak++;
      } else {
        break; // streak broken
      }
      prev = current;
    }

    return streak;
  }

  /// Calculate total poops (checkins + timer sessions)
  Future<int> _calculateTotalPoops(String userId) async {
    final db = await _dbHelper.database;

    final checkinResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM checkins WHERE userId = ?',
      [userId],
    );
    final timerResult = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM timer_sessions WHERE userId = ?',
      [userId],
    );

    final checkins = (checkinResult.first['cnt'] as int?) ?? 0;
    final timers = (timerResult.first['cnt'] as int?) ?? 0;

    return checkins + timers;
  }
}