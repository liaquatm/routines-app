import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4, // Incremented to 4 for multiple bank support
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    final batch = db.batch();

    // Habit Tables
    batch.execute('CREATE TABLE IF NOT EXISTS habit_definitions (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, iconName TEXT, colorValue INTEGER, frequencyType INTEGER, fixedDays TEXT, flexibleCount INTEGER)');
    batch.execute('CREATE TABLE IF NOT EXISTS habit_logs (id INTEGER PRIMARY KEY AUTOINCREMENT, habitId TEXT NOT NULL, date TEXT NOT NULL, FOREIGN KEY (habitId) REFERENCES habit_definitions (id) ON DELETE CASCADE)');

    // Reminder Tables
    batch.execute('CREATE TABLE IF NOT EXISTS reminders (id TEXT PRIMARY KEY, title TEXT NOT NULL, dateTime TEXT NOT NULL, isCompleted INTEGER DEFAULT 0)');

    // Finance Tables
    batch.execute('''
      CREATE TABLE IF NOT EXISTS finance_connections (
        id TEXT PRIMARY KEY,          -- Plaid item_id
        institutionName TEXT NOT NULL,
        lastSynced TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS finance_accounts (
        id TEXT PRIMARY KEY,
        connectionId TEXT NOT NULL,   -- Links to finance_connections
        name TEXT NOT NULL,
        officialName TEXT,
        mask TEXT,
        type TEXT,
        subtype TEXT,
        balanceCurrent REAL,
        balanceAvailable REAL,
        FOREIGN KEY (connectionId) REFERENCES finance_connections (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS finance_transactions (
        id TEXT PRIMARY KEY,
        accountId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        pending INTEGER DEFAULT 0,
        FOREIGN KEY (accountId) REFERENCES finance_accounts (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON finance_transactions (date)');
    batch.execute('CREATE INDEX IF NOT EXISTS idx_accounts_connection ON finance_accounts (connectionId)');

    await batch.commit();
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE IF NOT EXISTS reminders (id TEXT PRIMARY KEY, title TEXT NOT NULL, dateTime TEXT NOT NULL, isCompleted INTEGER DEFAULT 0)');
    }
    
    if (oldVersion < 3) {
      // Logic for initial finance tables (handled by v4 logic now)
    }

    if (oldVersion < 4) {
      final batch = db.batch();
      
      // 1. Add connections table
      batch.execute('''
        CREATE TABLE IF NOT EXISTS finance_connections (
          id TEXT PRIMARY KEY,
          institutionName TEXT NOT NULL,
          lastSynced TEXT
        )
      ''');

      // 2. Add connectionId column to accounts
      // Note: SQLite doesn't support adding NOT NULL columns with defaults easily,
      // but since we are refactoring, we'll recreate or migrate.
      // For this prototype, we'll just add the column.
      try {
        await db.execute('ALTER TABLE finance_accounts ADD COLUMN connectionId TEXT');
      } catch (e) {
        // Column might already exist
      }

      await batch.commit();
    }
  }

  Future close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
