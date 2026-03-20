import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('games.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Should copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);

        // Copy from asset
        ByteData data = await rootBundle.load(
          join('assets', 'database', filePath),
        );
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // Write and flush the bytes written
        await File(path).writeAsBytes(bytes, flush: true);
      } catch (e) {
        print('Error copying database from assets: $e');
        // If copying fails, let it create a new one via onCreate or just fail gracefully
      }
    }

    return await openDatabase(
      path,
      version: 17,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 17) {
      // Logic for adding switch/joker if someone is on an older version and didn't get them
      try {
        await db.execute(
          'ALTER TABLE wheel_segments ADD COLUMN is_switch INTEGER DEFAULT 0',
        );
      } catch (e) {}
      try {
        await db.execute(
          'ALTER TABLE wheel_segments ADD COLUMN is_joker INTEGER DEFAULT 0',
        );
      } catch (e) {}

      // Check if they already exist before inserting to avoid duplicates
      final switchExists = await db.query('wheel_segments', where: 'is_switch = 1');
      if (switchExists.isEmpty) {
        await db.insert('wheel_segments', {
          'text': 'سويتش',
          'points': 0,
          'is_question': 0,
          'is_switch': 1,
        });
      }

      final jokerExists = await db.query('wheel_segments', where: 'is_joker = 1');
      if (jokerExists.isEmpty) {
        await db.insert('wheel_segments', {
          'text': 'جوكر',
          'points': 0,
          'is_question': 0,
          'is_joker': 1,
        });
      }
    }
    if (oldVersion < 16) {
      // Logic for v16 was already merged into v17 above
    }
    if (oldVersion < 4) {
      await db.execute('DROP TABLE IF EXISTS wheel_segments');
      await _createWheelTable(db);
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE questions ADD COLUMN is_used INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 6) {
      await _createScoreLogsTable(db);
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE score_logs ADD COLUMN game_name TEXT');
      await db.execute('ALTER TABLE score_logs ADD COLUMN question TEXT');
      await db.execute('ALTER TABLE score_logs ADD COLUMN answer TEXT');
    }
    if (oldVersion < 8) {
      await _createQuestionCategoriesTable(db);
      await db.execute('''
        INSERT INTO question_categories (question_id, category_id, is_used)
        SELECT id, category_id, is_used FROM questions WHERE category_id IS NOT NULL
      ''');
    }
    if (oldVersion < 9) {
      await db.execute(
        "ALTER TABLE questions ADD COLUMN type TEXT NOT NULL DEFAULT 'essay'",
      );
      await db.execute("ALTER TABLE questions ADD COLUMN image_path TEXT");
      await db.execute("ALTER TABLE questions ADD COLUMN options_json TEXT");
      await db.execute(
        "ALTER TABLE questions ADD COLUMN correct_options_json TEXT",
      );
      await db.execute("ALTER TABLE questions ADD COLUMN tf_value INTEGER");
      await db.execute("ALTER TABLE questions ADD COLUMN grid_data_json TEXT");
    }
    if (oldVersion < 10) {
      await db.execute("ALTER TABLE questions ADD COLUMN image_data BLOB");
    }
    if (oldVersion < 11) {
      await db.execute(
        "ALTER TABLE questions ADD COLUMN is_multiple INTEGER DEFAULT 0",
      );
    }
    if (oldVersion < 12) {
      // Recreate questions table to remove obsolete category_id with NOT NULL constraint
      await db.execute('PRAGMA foreign_keys=OFF');

      await db.execute('''
        CREATE TABLE questions_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          answer TEXT NOT NULL,
          type TEXT NOT NULL DEFAULT 'essay',
          image_path TEXT,
          image_data BLOB,
          options_json TEXT,
          correct_options_json TEXT,
          tf_value INTEGER,
          grid_data_json TEXT,
          is_multiple INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        INSERT INTO questions_new (id, text, answer, type, image_path, image_data, options_json, correct_options_json, tf_value, grid_data_json, is_multiple)
        SELECT id, text, answer, type, image_path, image_data, options_json, correct_options_json, tf_value, grid_data_json, is_multiple FROM questions
      ''');

      await db.execute('DROP TABLE questions');
      await db.execute('ALTER TABLE questions_new RENAME TO questions');
      await db.execute('PRAGMA foreign_keys=ON');
    }
    if (oldVersion < 13) {
      await _createBankAlHazTables(db);
    }
    if (oldVersion < 14) {
      // Add missing columns to Bank Al-Haz tables
      try {
        await db.execute(
          'ALTER TABLE bah_stations ADD COLUMN owner_category_id INTEGER',
        );
        await db.execute(
          'ALTER TABLE bah_stations ADD COLUMN passer_category_id INTEGER',
        );
        await db.execute(
          'ALTER TABLE bah_stations ADD COLUMN requires_question INTEGER DEFAULT 1',
        );
        await db.execute('ALTER TABLE bah_cards ADD COLUMN type TEXT');
      } catch (e) {
        // Already exists or ignore
      }
    }
    if (oldVersion < 15) {
      try {
        await db.execute('ALTER TABLE bah_stations ADD COLUMN image_data BLOB');
        await db.execute('ALTER TABLE bah_cards ADD COLUMN image_data BLOB');
      } catch (e) {
        // Ignore
      }
    }
  }

  Future _createBankAlHazTables(Database db) async {
    // 1. Stations table
    await db.execute('''
      CREATE TABLE bah_stations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_path TEXT,
        image_data BLOB,
        type TEXT NOT NULL, -- 'question' | 'card'
        category_id INTEGER, -- Legacy
        owner_category_id INTEGER,
        passer_category_id INTEGER,
        requires_question INTEGER DEFAULT 1,
        card_type TEXT,
        buy_price REAL DEFAULT 0,
        base_rent REAL DEFAULT 0
      )
    ''');

    // 2. Buildings table (upgrades per station)
    await db.execute('''
      CREATE TABLE bah_buildings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        buy_price REAL DEFAULT 0,
        additional_rent REAL DEFAULT 0,
        FOREIGN KEY (station_id) REFERENCES bah_stations (id) ON DELETE CASCADE
      )
    ''');

    // 3. Action Cards table
    await db.execute('''
      CREATE TABLE bah_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        image_path TEXT,
        image_data BLOB,
        type TEXT,
        effect_type TEXT NOT NULL,
        effect_value INTEGER DEFAULT 0,
        target_station_name TEXT
      )
    ''');

    // 4. Game Settings (Singleton)
    await db.execute('''
      CREATE TABLE bah_settings (
        id INTEGER (1) PRIMARY KEY DEFAULT 1,
        initial_money REAL DEFAULT 1000,
        win_condition TEXT DEFAULT 'rounds',
        win_criteria TEXT DEFAULT 'moneyOnly',
        max_rounds INTEGER DEFAULT 10,
        max_time_minutes INTEGER DEFAULT 30
      )
    ''');

    // Insert default settings if not exists
    await db.insert('bah_settings', {
      'id': 1,
      'initial_money': 1000,
      'win_condition': 'rounds',
      'win_criteria': 'moneyOnly',
      'max_rounds': 10,
      'max_time_minutes': 30,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future _createQuestionCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE question_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        is_used INTEGER DEFAULT 0,
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createScoreLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE score_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        team_id INTEGER NOT NULL,
        points INTEGER NOT NULL,
        reason TEXT,
        game_name TEXT,
        question TEXT,
        answer TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _createWheelTable(Database db) async {
    await db.execute('''
      CREATE TABLE wheel_segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        points INTEGER NOT NULL,
        is_question INTEGER DEFAULT 0,
        category_ids TEXT,
        is_switch INTEGER DEFAULT 0,
        is_joker INTEGER DEFAULT 0
      )
    ''');

    await db.insert('wheel_segments', {
      'text': '10 نقاط',
      'points': 10,
      'is_question': 0,
    });
    await db.insert('wheel_segments', {
      'text': '20 نقطة',
      'points': 20,
      'is_question': 0,
    });
    await db.insert('wheel_segments', {
      'text': 'سؤال سهل',
      'points': 5,
      'is_question': 1,
      'category_ids': '1',
    });
    await db.insert('wheel_segments', {
      'text': 'سؤال صعب',
      'points': 15,
      'is_question': 1,
      'category_ids': '1',
    });
    await db.insert('wheel_segments', {
      'text': 'سويتش',
      'points': 0,
      'is_question': 0,
      'is_switch': 1,
    });
    await db.insert('wheel_segments', {
      'text': 'جوكر',
      'points': 0,
      'is_question': 0,
      'is_joker': 1,
    });
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        answer TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'essay',
        image_path TEXT,
        image_data BLOB,
        options_json TEXT,
        correct_options_json TEXT,
        tf_value INTEGER,
        grid_data_json TEXT,
        is_multiple INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE teams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        score INTEGER DEFAULT 0,
        players_count INTEGER DEFAULT 0
      )
    ''');

    await _createWheelTable(db);
    await _createScoreLogsTable(db);
    await _createQuestionCategoriesTable(db);
    await _createBankAlHazTables(db);

    await db.insert('categories', {'name': 'الكتاب المقدس'});
    await db.insert('categories', {'name': 'معلومات عامة'});
    await db.insert('categories', {'name': 'شخصيات'});
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
