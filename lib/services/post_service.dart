import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';

class PostService {
  final DBHelper _dbHelper = DBHelper();

  // ------------------ POSTS ------------------
  Future<int> addPost(String userId, String content) async {
    final db = await _dbHelper.database;
    return await db.insert('posts', {
      'userId': userId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllPosts() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT p.id, p.userId, p.content, p.timestamp, u.username
      FROM posts p
      JOIN users u ON u.id = p.userId
      ORDER BY datetime(p.timestamp) DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT p.id, p.content, p.timestamp, u.username
      FROM posts p
      JOIN users u ON u.id = p.userId
      WHERE p.userId = ?
      ORDER BY datetime(p.timestamp) DESC
    ''', [userId]);
  }

  Future<int> deletePost(int postId) async {
    final db = await _dbHelper.database;
    return await db.delete('posts', where: 'id = ?', whereArgs: [postId]);
  }

  // ------------------ COMMENTS ------------------
  Future<List<Map<String, dynamic>>> getCommentsForPost(int postId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT c.id, c.userId, c.content, c.timestamp, u.username
      FROM comments c
      JOIN users u ON u.id = c.userId
      WHERE c.postId = ?
      ORDER BY datetime(c.timestamp) ASC
    ''', [postId]);
  }

  Future<int> addComment(int postId, String userId, String content) async {
    final db = await _dbHelper.database;
    return await db.insert('comments', {
      'postId': postId,
      'userId': userId,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<int> deleteComment(int commentId) async {
    final db = await _dbHelper.database;
    return await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
  }

  // ------------------ LIKES ------------------
  Future<void> likePost(int postId, String userId) async {
    final db = await _dbHelper.database;

    // check if already liked
    final existing = await db.query(
      'likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );

    if (existing.isEmpty) {
      await db.insert('likes', {
        'postId': postId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> unlikePost(int postId, String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
  }

  Future<int> getLikeCount(int postId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM likes WHERE postId = ?',
      [postId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> isPostLiked(int postId, String userId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
    return result.isNotEmpty;
  }
}
