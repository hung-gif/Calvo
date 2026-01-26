// File: lib/services/local_db_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _database;

  // 1. Mở kết nối Database
  static Future<Database> getDatabase() async {
    if (_database != null) return _database!;
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'calvo_user.db');

    _database = await openDatabase(path, version: 1, 
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, theme TEXT, mode TEXT)'
        );
      }
    );
    return _database!;
  }

  // 2. Kiểm tra có user chưa (Dùng cho main.dart)
  static Future<bool> hasUserData() async {
    final db = await getDatabase();
    final result = await db.rawQuery('SELECT count(*) as count FROM users');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  // 3. Lưu user mới (Dùng cho onboarding_screen.dart)
  static Future<void> saveUser(String name, String theme, String mode) async {
    final db = await getDatabase();
    await db.insert(
      'users', 
      {'name': name, 'theme': theme, 'mode': mode},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 4. Lấy dữ liệu user (Dùng cho user_provider.dart) -> ĐÂY LÀ HÀM BẠN THIẾU
  static Future<Map<String, dynamic>?> getUserData() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }
}