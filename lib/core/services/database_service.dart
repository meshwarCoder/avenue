import 'package:sqflite/sqflite.dart';
import '../../core/utils/observability.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'line_database.db');

    return await openDatabase(
      path,
      version: 8, // Increment version
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 8) {
      await db.execute('DROP TABLE IF EXISTS tasks');
      await db.execute('DROP TABLE IF EXISTS default_tasks');
      await _createDB(db, newVersion);
    }
    if (oldVersion < 3) {
      // Add default_tasks table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS default_tasks (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          desc TEXT,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          category TEXT NOT NULL,
          weekdays TEXT NOT NULL,
          importance_type TEXT,
          server_updated_at TEXT NOT NULL DEFAULT '', 
          is_deleted INTEGER NOT NULL DEFAULT 0
        )
      ''');
    } else if (oldVersion < 4) {
      // Add missing sync columns if already on v3
      await db.execute(
        'ALTER TABLE default_tasks ADD COLUMN server_updated_at TEXT NOT NULL DEFAULT ""',
      );
      await db.execute(
        'ALTER TABLE default_tasks ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      // Add is_dirty column to track local changes for delta sync
      await db.execute(
        'ALTER TABLE tasks ADD COLUMN is_dirty INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE default_tasks ADD COLUMN is_dirty INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 6) {
      // Add embedding column for semantic search
      // DEPRECATED in v8 - removed
      try {
        await db.execute('ALTER TABLE tasks ADD COLUMN embedding TEXT');
        await db.execute('ALTER TABLE default_tasks ADD COLUMN embedding TEXT');
      } catch (e) {
        // Ignore if exists
      }
    }
    if (oldVersion < 7) {
      // Add hide_on for default tasks and default_task_id for regular tasks
      await db.execute('ALTER TABLE default_tasks ADD COLUMN hide_on TEXT');
      await db.execute('ALTER TABLE tasks ADD COLUMN default_task_id TEXT');
    }
    if (oldVersion < 8) {
      // Drop embedding column to save space
      // Note: SQLite DROP COLUMN support varies. If it fails, we ignore it.
      try {
        await db.execute('ALTER TABLE tasks DROP COLUMN embedding');
        await db.execute('ALTER TABLE default_tasks DROP COLUMN embedding');
      } catch (e) {
        AvenueLogger.log(
          event: 'DB_MAINTENANCE_WARN',
          level: LoggerLevel.WARN,
          layer: LoggerLayer.DB,
          payload: 'Could not drop embedding column: $e',
        );
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Tasks Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        desc TEXT,
        task_date TEXT NOT NULL,
        start_time TEXT,
        end_time TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        one_time INTEGER NOT NULL DEFAULT 1,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        server_updated_at TEXT NOT NULL,
        importance_type TEXT,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        default_task_id TEXT
      )
    ''');
    // Removed embedding column
    // Default Tasks Table (Recurring)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS default_tasks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        desc TEXT,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        category TEXT NOT NULL,
        weekdays TEXT NOT NULL,
        importance_type TEXT,
        server_updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        is_dirty INTEGER NOT NULL DEFAULT 0,
        hide_on TEXT
      )
    ''');
    // Removed embedding column
    // Settings Table (for last_sync_timestamp, etc.)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  Future<void> clearUserData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('default_tasks');
      await txn.delete(
        'settings',
        where: 'key = ?',
        whereArgs: ['last_sync_timestamp'],
      );
    });
    AvenueLogger.log(
      event: 'DB_MAINTENANCE_SUCCESS',
      layer: LoggerLayer.DB,
      payload: 'Local user data cleared.',
    );
  }
}
