import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// The DatabaseService is the single "Control Center" for your entire app's storage.
/// It sets up the physical database file (my_data.db) on the phone.
class DatabaseService {
  // Singleton pattern: ensures only one connection is open at a time.
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // getDatabasesPath() finds the platform-specific safe location on the phone.
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        // This ensures that deleting a habit automatically deletes its logs
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// The "Master Blueprint" for all app features.
  Future _createDB(Database db, int version) async {
    final batch = db.batch();

    // --- HABIT FEATURE TABLES ---
    batch.execute('''
      CREATE TABLE IF NOT EXISTS habit_definitions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconName TEXT,
        colorValue INTEGER,
        frequencyType INTEGER,
        fixedDays TEXT,
        flexibleCount INTEGER
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habit_definitions (id) ON DELETE CASCADE
      )
    ''');

    // --- REMINDER FEATURE TABLES ---
    batch.execute('''
      CREATE TABLE IF NOT EXISTS reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0
      )
    ''');

    await batch.commit();
  }

  Future close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reminders (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          dateTime TEXT NOT NULL,
          isCompleted INTEGER DEFAULT 0
        )
      ''');
    }
  }
}
