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
      version: 1,
      onCreate: _createDB,
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

    // Stores the general info about a habit (Name, Color, etc.)
    batch.execute('''
      CREATE TABLE habit_definitions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconName TEXT,
        colorValue INTEGER,
        frequencyType INTEGER,
        fixedDays TEXT, -- We will store the list as a string like "1,2,3"
        flexibleCount INTEGER
      )
    ''');

    // Stores every time a habit is completed.
    batch.execute('''
      CREATE TABLE habit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId TEXT NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (habitId) REFERENCES habit_definitions (id) ON DELETE CASCADE
      )
    ''');

    await batch.commit();

    // --- FUTURE: WORKOUT TABLES ---
    // We will add 'workout_definitions' and 'workout_logs' here later.

    // --- FUTURE: BUDGET TABLES ---
    // We will add 'budget_categories' and 'transactions' here later.
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
