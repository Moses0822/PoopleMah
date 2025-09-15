import '../db_helper.dart';
import 'package:sqflite/sqflite.dart';

class StatsService {
  final DBHelper _dbHelper = DBHelper();

  Future<int> getCheckinCount(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM checkins WHERE userId = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
