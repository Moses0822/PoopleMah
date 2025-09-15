import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'friends.db');
    return await openDatabase(
      path,
      version: 8, // ⬅ bump to 8
      onCreate: (db, version) async {
        await _createAllTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('Upgrading database from version $oldVersion to $newVersion');

        await _ensureTimerSessionsTableExists(db);
        if (oldVersion < 4) {
          await _ensureCheckinsTableExists(db);
        }
        if (oldVersion < 7) {
          await _ensureLikesTableExists(db);
        }
        if (oldVersion < 8) { // ✅ ensure startTime column exists
          await _addStartTimeColumn(db);
        }
      },
    );
  }

  Future<void> _createAllTables(Database db) async {
    // Users table (uid from Firebase)
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE
        profilePicturePath TEXT
      )
    ''');

    // Friends table (link users by UID)
    await db.execute('''
      CREATE TABLE friends(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        friendId TEXT,
        status TEXT,
        FOREIGN KEY(userId) REFERENCES users(id),
        FOREIGN KEY(friendId) REFERENCES users(id)
      )
    ''');

    // Stats table (linked by UID)
    await db.execute('''
      CREATE TABLE stats(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        streak INTEGER DEFAULT 0,
        totalPoops INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Posts table
    await db.execute('''
      CREATE TABLE posts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        content TEXT,
        timestamp TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Comments table
    await db.execute('''
      CREATE TABLE comments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER,
        userId TEXT,
        content TEXT,
        timestamp TEXT,
        FOREIGN KEY(postId) REFERENCES posts(id),
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    //Likes table
    await db.execute('''
      CREATE TABLE likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        postId INTEGER NOT NULL,
        userId TEXT NOT NULL,  -- Firebase UID
        timestamp TEXT NOT NULL,
        FOREIGN KEY (postId) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Locations table
    await db.execute('''
      CREATE TABLE locations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Checkins table for daily check-ins
    await db.execute('''
      CREATE TABLE checkins(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        stoolType INTEGER,
        feelingRating REAL,
        notes TEXT,
        hasPhoto INTEGER DEFAULT 0,
        photoPath TEXT,
        timestamp TEXT,
        dateOnly TEXT,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Timer sessions table for poop timer data
    await db.execute('''
      CREATE TABLE timer_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT,
        username TEXT,
        duration INTEGER,
        quality TEXT,
        size INTEGER,
        notes TEXT,
        timestamp TEXT,
        dateOnly TEXT,
        startTime TEXT,  -- ✅ Added startTime column
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');
  }

  Future<void> _ensureTimerSessionsTableExists(Database db) async {
    // Check if timer_sessions table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='timer_sessions'"
    );
    
    if (tables.isEmpty) {
      // Create the timer_sessions table with startTime column
      await db.execute('''
        CREATE TABLE timer_sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT,
          username TEXT,
          duration INTEGER,
          quality TEXT,
          size INTEGER,
          notes TEXT,
          timestamp TEXT,
          dateOnly TEXT,
          startTime TEXT,  -- ✅ Added startTime column
          FOREIGN KEY(userId) REFERENCES users(id)
        )
      ''');
      print('Created timer_sessions table with startTime column');
    } else {
      print('timer_sessions table already exists');
      
      // Check if startTime column exists and add it if it doesn't
      final columns = await db.rawQuery("PRAGMA table_info(timer_sessions)");
      final hasStartTime = columns.any((column) => column['name'] == 'startTime');
      
      if (!hasStartTime) {
        await db.execute('ALTER TABLE timer_sessions ADD COLUMN startTime TEXT');
        print('Added startTime column to existing timer_sessions table');
      }
    }
  }

  Future<void> _ensureCheckinsTableExists(Database db) async {
    // Check if checkins table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='checkins'"
    );
    
    if (tables.isEmpty) {
      // Create the checkins table
      await db.execute('''
        CREATE TABLE checkins(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT,
          stoolType INTEGER,
          feelingRating REAL,
          notes TEXT,
          hasPhoto INTEGER DEFAULT 0,
          photoPath TEXT,
          timestamp TEXT,
          dateOnly TEXT,
          FOREIGN KEY(userId) REFERENCES users(id)
        )
      ''');
      print('Created checkins table');
    }
  }

  Future<void> _ensureLikesTableExists(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='likes'"
    );

    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE likes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          postId INTEGER NOT NULL,
          userId TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (postId) REFERENCES posts(id) ON DELETE CASCADE,
          FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      print('Created likes table');
    } else {
      print('likes table already exists');
    }
  }

  Future<void> _addStartTimeColumn(Database db) async {
    try {
      // Check if startTime column already exists
      final columns = await db.rawQuery("PRAGMA table_info(timer_sessions)");
      final hasStartTime = columns.any((column) => column['name'] == 'startTime');
      
      if (!hasStartTime) {
        await db.execute('ALTER TABLE timer_sessions ADD COLUMN startTime TEXT');
        print('Added startTime column to timer_sessions table via migration');
      } else {
        print('startTime column already exists in timer_sessions table');
      }
    } catch (e) {
      print('Error adding startTime column: $e');
    }
  }

  // Method to manually ensure timer_sessions table exists (for debugging)
  Future<void> ensureTimerSessionsTable() async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
  }

  // Normalize dateOnly (yyyy-MM-dd)
String _normalizeDate(DateTime date) {
  return "${date.year.toString().padLeft(4, '0')}-"
         "${date.month.toString().padLeft(2, '0')}-"
         "${date.day.toString().padLeft(2, '0')}";
}
  
  // Save a new check-in
  Future<int> insertCheckin(Map<String, dynamic> checkin) async {
    final db = await database;
    final now = DateTime.now();
    checkin['timestamp'] ??= now.toIso8601String();
    checkin['dateOnly'] ??= _normalizeDate(now);
    return await db.insert('checkins', checkin);
  }

  // Get all check-ins for a user
  Future<List<Map<String, dynamic>>> getCheckins(String userId) async {
    final db = await database;
    return await db.query(
      'checkins',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  // Get check-ins for a specific date
  Future<List<Map<String, dynamic>>> getCheckinsForDate(String userId, String date) async {
    final db = await database;
    return await db.query(
      'checkins',
      where: 'userId = ? AND dateOnly = ?',
      whereArgs: [userId, date],
      orderBy: 'timestamp DESC',
    );
  }

  // Get recent check-ins (last N days)
  Future<List<Map<String, dynamic>>> getRecentCheckins(String userId, int days) async {
    final db = await database;
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
    final String cutoffString = cutoffDate.toIso8601String();
    
    return await db.query(
      'checkins',
      where: 'userId = ? AND timestamp >= ?',
      whereArgs: [userId, cutoffString],
      orderBy: 'timestamp DESC',
    );
  }

  // Update a check-in
  Future<int> updateCheckin(int id, Map<String, dynamic> checkin) async {
    final db = await database;
    if (checkin['dateOnly'] == null && checkin['timestamp'] != null) {
      final ts = DateTime.tryParse(checkin['timestamp']);
      if (ts != null) checkin['dateOnly'] = _normalizeDate(ts);
    }
    return await db.update('checkins', checkin,
        where: 'id = ?', whereArgs: [id]);
  }

  // Delete a check-in
  Future<int> deleteCheckin(int id) async {
    final db = await database;
    return await db.delete(
      'checkins',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get check-in statistics
  Future<Map<String, dynamic>> getCheckinStats(String userId) async {
    final db = await database;
    
    // Get total count
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM checkins WHERE userId = ?',
      [userId]
    );
    
    // Get average feeling rating
    final avgResult = await db.rawQuery(
      'SELECT AVG(feelingRating) as avgFeeling FROM checkins WHERE userId = ?',
      [userId]
    );
    
    // Get most common stool type
    final commonTypeResult = await db.rawQuery(
      '''SELECT stoolType, COUNT(*) as count FROM checkins 
         WHERE userId = ? 
         GROUP BY stoolType 
         ORDER BY count DESC 
         LIMIT 1''',
      [userId]
    );
    
    return {
      'totalCheckins': totalResult.first['total'] ?? 0,
      'averageFeeling': avgResult.first['avgFeeling'] ?? 0.0,
      'mostCommonType': commonTypeResult.isNotEmpty ? commonTypeResult.first['stoolType'] : null,
    };
  }

  // Add this debug method to your DBHelper class to troubleshoot the streak issue
  Future<void> debugStreakCalculation(String userId) async {
    final db = await database;
    
    print("=== DEBUGGING STREAK CALCULATION ===");
    
    // 1. Check if checkins table exists and has data
    final checkins = await db.query('checkins', where: 'userId = ?', whereArgs: [userId]);
    print("Total checkins for user: ${checkins.length}");
    
    if (checkins.isEmpty) {
      print("❌ No checkins found for user $userId");
      return;
    }
    
    // 2. Show all checkins with their timestamps and dateOnly values
    print("\nAll checkins:");
    for (var checkin in checkins) {
      print("  - Timestamp: ${checkin['timestamp']}, DateOnly: ${checkin['dateOnly']}, StoolType: ${checkin['stoolType']}");
    }
    
    // 3. Check distinct dates used in streak calculation
    final distinctDates = await db.rawQuery('''
      SELECT DISTINCT dateOnly 
      FROM checkins 
      WHERE userId = ? 
      ORDER BY dateOnly DESC
    ''', [userId]);
    
    print("\nDistinct dates (newest first):");
    for (var date in distinctDates) {
      print("  - ${date['dateOnly']}");
    }
    
    // 4. Check today's date format
    final today = DateTime.now();
    final todayNormalized = "${today.year.toString().padLeft(4, '0')}-"
                          "${today.month.toString().padLeft(2, '0')}-"
                          "${today.day.toString().padLeft(2, '0')}";
    final yesterdayNormalized = "${today.subtract(Duration(days: 1)).year.toString().padLeft(4, '0')}-"
                              "${today.subtract(Duration(days: 1)).month.toString().padLeft(2, '0')}-"
                              "${today.subtract(Duration(days: 1)).day.toString().padLeft(2, '0')}";
    
    print("\nToday's normalized date: $todayNormalized");
    print("Yesterday's normalized date: $yesterdayNormalized");
    
    // 5. Run the actual streak calculation with debug output
    final result = await db.rawQuery('''
      SELECT DISTINCT dateOnly 
      FROM checkins 
      WHERE userId = ? 
      ORDER BY dateOnly DESC
    ''', [userId]);

    if (result.isEmpty) {
      print("❌ No results from streak query");
      return;
    }

    final List<DateTime> dates = result
        .map((row) => DateTime.parse(row['dateOnly'] as String))
        .toList();

    print("\nParsed dates:");
    for (var date in dates) {
      print("  - $date");
    }

    // Manual streak calculation with debug output
    int streak = 0;
    DateTime currentDay = DateTime(today.year, today.month, today.day);
    
    print("\nStreak calculation:");
    print("Starting currentDay: $currentDay");
    
    for (int i = 0; i < dates.length; i++) {
      DateTime normalized = DateTime(dates[i].year, dates[i].month, dates[i].day);
      print("\nChecking date[$i]: $normalized");
      print("Current streak: $streak");
      print("Current day to match: $currentDay");
      
      if (streak == 0) {
        if (normalized == currentDay) {
          streak++;
          print("✅ Found today's checkin, streak = $streak");
        } else if (normalized == currentDay.subtract(const Duration(days: 1))) {
          streak++;
          currentDay = normalized;
          print("✅ Found yesterday's checkin, streak = $streak, currentDay = $currentDay");
        } else {
          print("❌ First date is not today or yesterday, breaking");
          break;
        }
      } else {
        DateTime expectedDay = currentDay.subtract(const Duration(days: 1));
        print("Expected previous day: $expectedDay");
        
        if (normalized == expectedDay) {
          streak++;
          currentDay = normalized;
          print("✅ Found consecutive day, streak = $streak, currentDay = $currentDay");
        } else {
          print("❌ Gap found, breaking streak");
          break;
        }
      }
    }
    
    print("\n=== FINAL STREAK: $streak ===");
  }

  // Also add this method to fix potential issues with date normalization in checkins
  Future<void> fixCheckinDates(String userId) async {
    final db = await database;
    
    print("=== FIXING CHECKIN DATES ===");
    
    // Get all checkins that might have incorrect dateOnly values
    final checkins = await db.query('checkins', where: 'userId = ?', whereArgs: [userId]);
    
    for (var checkin in checkins) {
      final timestamp = checkin['timestamp'] as String?;
      final currentDateOnly = checkin['dateOnly'] as String?;
      
      if (timestamp != null) {
        final dateTime = DateTime.tryParse(timestamp);
        if (dateTime != null) {
          final correctDateOnly = "${dateTime.year.toString().padLeft(4, '0')}-"
                                "${dateTime.month.toString().padLeft(2, '0')}-"
                                "${dateTime.day.toString().padLeft(2, '0')}";
          
          if (currentDateOnly != correctDateOnly) {
            print("Fixing checkin ${checkin['id']}: $currentDateOnly -> $correctDateOnly");
            await db.update(
              'checkins', 
              {'dateOnly': correctDateOnly}, 
              where: 'id = ?', 
              whereArgs: [checkin['id']]
            );
          }
        }
      }
    }
    
    print("Date fixing complete");
  }

  // Updated streak calculation method with better error handling
  Future<int> getCheckinStreakFixed(String userId) async {
    final db = await database;

    // Get distinct check-in dates, ordered latest → oldest
    final result = await db.rawQuery('''
      SELECT DISTINCT dateOnly 
      FROM checkins 
      WHERE userId = ? AND dateOnly IS NOT NULL
      ORDER BY dateOnly DESC
    ''', [userId]);

    if (result.isEmpty) return 0;

    // Convert result into a list of DateTime objects
    final List<DateTime> dates = [];
    for (var row in result) {
      try {
        final dateStr = row['dateOnly'] as String;
        final date = DateTime.parse(dateStr);
        dates.add(date);
      } catch (e) {
        print('Error parsing date: ${row['dateOnly']}, error: $e');
        continue;
      }
    }

    if (dates.isEmpty) return 0;

    // Start streak calculation
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime currentDay = DateTime(today.year, today.month, today.day);

    for (final date in dates) {
      // Normalize dateOnly (strip time)
      DateTime normalized = DateTime(date.year, date.month, date.day);

      if (streak == 0) {
        // First check — must be today or yesterday to start streak
        if (normalized == currentDay) {
          streak++;
        } else if (normalized == currentDay.subtract(const Duration(days: 1))) {
          streak++;
          currentDay = normalized;
        } else {
          break; // gap, no streak
        }
      } else {
        // Check consecutive previous days
        DateTime expectedDay = currentDay.subtract(const Duration(days: 1));
        if (normalized == expectedDay) {
          streak++;
          currentDay = normalized;
        } else {
          break; // gap in streak
        }
      }
    }

    return streak;
  }

  // Add this method to DBHelper class
  Future<void> updateStreakAfterCheckin(String userId) async {
    final calculatedStreak = await getCheckinStreakFixed(userId);
    final db = await database;
    
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
    
    print('Updated streak for user $userId: $calculatedStreak');
  }


  // ✅ Methods for timer sessions
  
  // Save a new timer session
  Future<int> insertTimerSession(Map<String, dynamic> session) async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
    final now = DateTime.now();
    session['timestamp'] ??= now.toIso8601String();
    session['dateOnly'] ??= _normalizeDate(now);
    return await db.insert('timer_sessions', session);
  }

  // Get all timer sessions for a user
  Future<List<Map<String, dynamic>>> getTimerSessions(String userId) async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
    return await db.query(
      'timer_sessions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  // Get timer sessions for a specific date
  Future<List<Map<String, dynamic>>> getTimerSessionsForDate(String userId, String date) async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
    return await db.query(
      'timer_sessions',
      where: 'userId = ? AND dateOnly = ?',
      whereArgs: [userId, date],
      orderBy: 'timestamp DESC',
    );
  }

  // Get recent timer sessions (last N days)
  Future<List<Map<String, dynamic>>> getRecentTimerSessions(String userId, int days) async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: days));
    final String cutoffString = cutoffDate.toIso8601String();
    
    return await db.query(
      'timer_sessions',
      where: 'userId = ? AND timestamp >= ?',
      whereArgs: [userId, cutoffString],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> updateTimerSession(int id, Map<String, dynamic> session) async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
    if (session['dateOnly'] == null && session['timestamp'] != null) {
      final ts = DateTime.tryParse(session['timestamp']);
      if (ts != null) session['dateOnly'] = _normalizeDate(ts);
    }
    return await db.update('timer_sessions', session,
        where: 'id = ?', whereArgs: [id]);
  }

  // Delete a timer session
  Future<int> deleteTimerSession(int id) async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
    return await db.delete(
      'timer_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get timer session statistics
  Future<Map<String, dynamic>> getTimerStats(String userId) async {
    final db = await database;
    await _ensureTimerSessionsTableExists(db);
    
    // Get total count
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM timer_sessions WHERE userId = ?',
      [userId]
    );
    
    // Get average duration
    final avgDurationResult = await db.rawQuery(
      'SELECT AVG(duration) as avgDuration FROM timer_sessions WHERE userId = ?',
      [userId]
    );
    
    // Get total time spent
    final totalTimeResult = await db.rawQuery(
      'SELECT SUM(duration) as totalTime FROM timer_sessions WHERE userId = ?',
      [userId]
    );
    
    // Get average size rating
    final avgSizeResult = await db.rawQuery(
      'SELECT AVG(size) as avgSize FROM timer_sessions WHERE userId = ?',
      [userId]
    );
    
    // Get most common quality
    final commonQualityResult = await db.rawQuery(
      '''SELECT quality, COUNT(*) as count FROM timer_sessions 
         WHERE userId = ? 
         GROUP BY quality 
         ORDER BY count DESC 
         LIMIT 1''',
      [userId]
    );
    
    return {
      'totalSessions': totalResult.first['total'] ?? 0,
      'averageDuration': avgDurationResult.first['avgDuration'] ?? 0.0,
      'totalTime': totalTimeResult.first['totalTime'] ?? 0,
      'averageSize': avgSizeResult.first['avgSize'] ?? 0.0,
      'mostCommonQuality': commonQualityResult.isNotEmpty ? commonQualityResult.first['quality'] : null,
    };
  }

  // Get combined stats (both checkins and timer sessions)
  Future<Map<String, dynamic>> getCombinedStats(String userId) async {
    final checkinStats = await getCheckinStats(userId);
    final timerStats = await getTimerStats(userId);
    
    return {
      ...checkinStats,
      ...timerStats,
      'totalActivities': (checkinStats['totalCheckins'] as int) + (timerStats['totalSessions'] as int),
    };
  }

  // ✅ Methods for likes
  
  // Add a like to a post
  Future<int> insertLike(int postId, String userId) async {
    final db = await database;
    return await db.insert('likes', {
      'postId': postId,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Remove a like from a post
  Future<int> deleteLike(int postId, String userId) async {
    final db = await database;
    return await db.delete(
      'likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
  }

  // Check if user has liked a post
  Future<bool> hasUserLikedPost(int postId, String userId) async {
    final db = await database;
    final result = await db.query(
      'likes',
      where: 'postId = ? AND userId = ?',
      whereArgs: [postId, userId],
    );
    return result.isNotEmpty;
  }

  // Get like count for a post
  Future<int> getLikeCount(int postId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM likes WHERE postId = ?',
      [postId]
    );
    return result.first['count'] as int? ?? 0;
  }

  // Get all likes for a post
  Future<List<Map<String, dynamic>>> getPostLikes(int postId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, u.username 
      FROM likes l 
      LEFT JOIN users u ON l.userId = u.id 
      WHERE l.postId = ? 
      ORDER BY l.timestamp DESC
    ''', [postId]);
  }

  // ✅ Additional utility methods
  
  // Clear all data (for testing/debugging)
  Future<void> clearAllData() async {
    final db = await database;
    final tables = ['users', 'friends', 'stats', 'posts', 'comments', 'likes', 'locations', 'checkins', 'timer_sessions'];
    for (String table in tables) {
      await db.delete(table);
    }
    print('Cleared all data from database');
  }

  Future<DateTime?> getLastCheckinDate(String userId) async {
  final db = await database;
  final result = await db.query(
    'checkins',
    where: 'userId = ?',
    whereArgs: [userId],
    orderBy: 'timestamp DESC',
    limit: 1,
  );
  if (result.isNotEmpty) {
    return DateTime.tryParse(result.first['timestamp'] as String);
  }
  return null;
}

  // Get database info for debugging
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final db = await database;
    
    // Get all table names
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'"
    );
    
    Map<String, dynamic> info = {
      'databasePath': db.path,
      'tables': [],
    };
    
    for (var table in tables) {
      String tableName = table['name'] as String;
      if (!tableName.startsWith('sqlite_')) {
        final count = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
        final columns = await db.rawQuery("PRAGMA table_info($tableName)");
        
        info['tables'].add({
          'name': tableName,
          'rowCount': count.first['count'],
          'columns': columns.map((col) => col['name']).toList(),
        });
      }
    }
    
    return info;
  }
  
  // Update username for a user
  Future<int> updateUsername(String userId, String newUsername) async {
    final db = await database;
    
    // Check if username is already taken by another user
    final existingUser = await db.query(
      'users',
      where: 'username = ? AND id != ?',
      whereArgs: [newUsername, userId],
    );
    
    if (existingUser.isNotEmpty) {
      throw Exception('Username is already taken');
    }
    
    // Update the username
    return await db.update(
      'users',
      {'username': newUsername},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Get user information by ID
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  // Update user information (for future use if you add more user fields)
  Future<int> updateUser(String userId, Map<String, dynamic> userData) async {
    final db = await database;
    return await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Check if username exists (excluding current user)
  Future<bool> isUsernameAvailable(String username, String currentUserId) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ? AND id != ?',
      whereArgs: [username, currentUserId],
      limit: 1,
    );
    
    return result.isEmpty;
  }
}