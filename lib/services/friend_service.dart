// friend_service.dart
import '../db_helper.dart';

class FriendService {
  final DBHelper _dbHelper = DBHelper();

  // ✅ Add or update a user (Firebase UID + username)
  Future<void> addUser(String uid, String username) async {
    final db = await _dbHelper.database;
    final existing =
        await db.query('users', where: 'id = ?', whereArgs: [uid]);

    if (existing.isEmpty) {
      await db.insert('users', {'id': uid, 'username': username});
    } else {
      await db.update(
        'users',
        {'username': username},
        where: 'id = ?',
        whereArgs: [uid],
      );
    }
  }

  // ✅ Find a user's UID by username
  Future<String?> getUserIdByUsername(String username) async {
    final db = await _dbHelper.database;
    final result =
        await db.query('users', where: 'username = ?', whereArgs: [username]);

    if (result.isNotEmpty) {
      return result.first['id'] as String;
    }
    return null;
  }

  // ✅ Send friend request (userId -> friendId)
  Future<int> sendFriendRequest(String userId, String friendId) async {
    final db = await _dbHelper.database;
    return await db.insert('friends', {
      'userId': userId,
      'friendId': friendId,
      'status': 'pending',
    });
  }

  // ✅ Get pending requests where current user is the *target* (friendId)
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT f.id as requestId, u.id as fromUid, u.username
      FROM friends f
      JOIN users u ON u.id = f.userId
      WHERE f.friendId = ? AND f.status = 'pending'
      ORDER BY f.id DESC
    ''', [userId]);
  }

  // ✅ Accept the request (by friends table id)
  Future<int> acceptRequest(int requestId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'friends',
      {'status': 'accepted'},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  // ✅ Delete a friend request (ignore)
  Future<int> deleteRequest(int requestId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'friends',
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  // ✅ Remove existing friend relation (bi-directional)
  Future<int> removeFriend(String userId, String friendId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'friends',
      where: '(userId = ? AND friendId = ?) OR (userId = ? AND friendId = ?)',
      whereArgs: [userId, friendId, friendId, userId],
    );
  }

  // Get accepted friends (list, bi-directional)
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT u.id, u.username, f.status
      FROM friends f
      JOIN users u 
        ON (u.id = f.friendId AND f.userId = ?)   -- case: I sent request
        OR (u.id = f.userId AND f.friendId = ?)   -- case: I received request
      WHERE f.status = 'accepted'
    ''', [userId, userId]);
  }

  Future<List<Map<String, dynamic>>> getLeaderboardForUser(String userId) async {
    final db = await DBHelper().database;
    
    // Get friends with their current streaks
    final result = await db.rawQuery('''
      SELECT u.id, u.username, s.streak as points
      FROM users u
      LEFT JOIN stats s ON u.id = s.userId  
      INNER JOIN friends f ON (f.friendId = u.id OR f.userId = u.id)
      WHERE (f.userId = ? OR f.friendId = ?) AND f.status = 'accepted'
      ORDER BY s.streak DESC
    ''', [userId, userId]);
    
    return result;
  }

}
