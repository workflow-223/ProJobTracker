import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static Database? _database;

  static Future<Database> getInstance() async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'projobtracker.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            created_at TEXT DEFAULT (datetime('now'))
          )
        ''');
        await db.execute('''
          CREATE TABLE jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            company TEXT NOT NULL,
            position TEXT NOT NULL,
            date_applied TEXT,
            deadline TEXT,
            notes TEXT,
            status TEXT DEFAULT 'Applied',
            salary REAL DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now')),
            updated_at TEXT DEFAULT (datetime('now')),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _database!;
  }

  // --- User methods ---

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await getInstance();
    final users = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return users.isNotEmpty ? users.first : null;
  }

  static Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await getInstance();
    final users = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return users.isNotEmpty ? users.first : null;
  }

  static Future<int> createUser(String email, String passwordHash, String firstName, String lastName) async {
    final db = await getInstance();
    return await db.insert('users', {
      'email': email,
      'password_hash': passwordHash,
      'first_name': firstName,
      'last_name': lastName,
    });
  }

  // --- Job methods ---

  static Future<List<Map<String, dynamic>>> getJobsByUserId(int userId) async {
    final db = await getInstance();
    return await db.query(
      'jobs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
  }

  static Future<Map<String, dynamic>?> getJobById(int jobId) async {
    final db = await getInstance();
    final jobs = await db.query('jobs', where: 'id = ?', whereArgs: [jobId]);
    return jobs.isNotEmpty ? jobs.first : null;
  }

  static Future<int> addJob(Map<String, dynamic> job) async {
    final db = await getInstance();
    return await db.insert('jobs', job);
  }

  static Future<int> updateJob(int jobId, Map<String, dynamic> job) async {
    final db = await getInstance();
    job['updated_at'] = DateTime.now().toIso8601String().substring(0, 19).replaceFirst('T', ' ');
    return await db.update('jobs', job, where: 'id = ?', whereArgs: [jobId]);
  }

  static Future<int> deleteJob(int jobId) async {
    final db = await getInstance();
    return await db.delete('jobs', where: 'id = ?', whereArgs: [jobId]);
  }

  static Future<bool> jobExists(int userId, String company, String position) async {
    final db = await getInstance();
    final result = await db.query(
      'jobs',
      where: 'user_id = ? AND company = ? AND position = ?',
      whereArgs: [userId, company, position],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // --- Chart aggregation methods ---

  static Future<List<Map<String, dynamic>>> getStatusCounts(int userId) async {
    final db = await getInstance();
    return await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM jobs WHERE user_id = ? GROUP BY status',
      [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getPositionCounts(int userId) async {
    final db = await getInstance();
    return await db.rawQuery(
      'SELECT position, COUNT(*) as count FROM jobs WHERE user_id = ? GROUP BY position',
      [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getAvgSalaryByPosition(int userId) async {
    final db = await getInstance();
    return await db.rawQuery(
      'SELECT position, AVG(salary) as avg_salary, COUNT(*) as count FROM jobs WHERE user_id = ? AND salary > 0 GROUP BY position',
      [userId],
    );
  }
}
