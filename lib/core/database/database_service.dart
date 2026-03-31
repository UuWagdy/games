import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/games/bank_al_haz/data/sources/bank_al_haz_default_data.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  
  // No longer needed manually. We now use an automated fingerprinting 
  // of the games.db asset to detect changes and sync automatically.
  // static const int _dbRevision = 4; 

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('games.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    final exists = await databaseExists(path);
    final prefs = await SharedPreferences.getInstance();
    
    // Load asset and calculate fingerprint to see if the database file in assets has changed
    final assetData = await rootBundle.load('assets/database/games.db');
    final fingerprint = _calculateFingerprint(assetData);
    
    final lastSyncedFingerprint = prefs.getString('db_fingerprint') ?? '';
    final needsSync = lastSyncedFingerprint != fingerprint;

    if (!exists) {
      await _copyFromAssets(path);
      await prefs.setString('db_fingerprint', fingerprint);
    } else if (needsSync) {
      print('Database Sync/Update detected (Fingerprint changed). Preserving settings...');
      
      Map<String, List<Map<String, dynamic>>> backup = {};
      final userTables = [
        'teams', 
        'wheel_segments', 
        'bah_settings', 
        'bah_game_state', 
        'score_logs',
        'categories', 
        'questions',
        'question_categories'
      ];

      try {
        final oldDb = await openDatabase(path);
        for (var table in userTables) {
          try {
            backup[table] = await oldDb.query(table);
          } catch (_) {} 
        }
        await oldDb.close();

        await _copyFromAssets(path);

        final newDb = await openDatabase(path);
        await newDb.transaction((txn) async {
          // Check if the new asset database already has data for questions/categories
          // If the developer pre-populated the asset, we trust it and don't restore old backups
          // to avoid "pollution" or merging (increased counts).
          final List<Map<String, dynamic>> assetQ = await txn.query('questions', limit: 1);
          final List<Map<String, dynamic>> assetC = await txn.query('categories', limit: 1);
          
          bool shouldRestoreQuestions = assetQ.isEmpty;
          bool shouldRestoreCategories = assetC.isEmpty;

          for (var table in userTables) {
            final data = backup[table];
            if (data != null && data.isNotEmpty) {
              // Conditional restoration
              if ((table == 'questions' || table == 'question_categories') && !shouldRestoreQuestions) continue;
              if (table == 'categories' && !shouldRestoreCategories) continue;

              // If we are restoring questions/categories, we clear the table first
              // but given the logic above, we only reach here if they were empty anyway,
              // or for other non-question tables (like teams, settings).
              if (table != 'questions' && table != 'categories' && table != 'question_categories') {
                 // For settings, segments, etc., we clear and replace with user's backup
                 await txn.delete(table);
              }

              for (var row in data) {
                await txn.insert(
                  table, 
                  row, 
                  conflictAlgorithm: (table == 'questions' || table == 'categories' || table == 'question_categories')
                    ? ConflictAlgorithm.ignore 
                    : ConflictAlgorithm.replace
                );
              }
            }
          }
        });
        await newDb.close();
        
        await prefs.setString('db_fingerprint', fingerprint);
        print('Database update completed. User settings and wheel segments preserved.');
      } catch (e) {
        print('Error during incremental database sync: $e');
      }
    }

    return await openDatabase(
      path,
      version: 28,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  String _calculateFingerprint(ByteData data) {
    // Generate a unique fingerprint based on file size and content sampling
    int len = data.lengthInBytes;
    if (len == 0) return 'empty';
    
    // Sum up some bytes from start, middle and end as a lightweight hash
    int checksum = 0;
    int samplePoints = 50; 
    
    // Sample first part
    for (int i = 0; i < samplePoints && i < len; i++) {
      checksum += data.getUint8(i);
    }
    // Sample middle part
    int mid = len ~/ 2;
    for (int i = 0; i < samplePoints && (mid + i) < len; i++) {
      checksum += data.getUint8(mid + i);
    }
    // Sample end part
    for (int i = 0; i < samplePoints && (len - 1 - i) >= 0; i++) {
      checksum += data.getUint8(len - 1 - i);
    }
    
    return '$len-$checksum';
  }

  Future<void> _copyFromAssets(String path) async {
    await Directory(dirname(path)).create(recursive: true);
    ByteData data = await rootBundle.load('assets/database/games.db');
    List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
  }

  Future<void> forceSyncFromAssets() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'games.db');
    
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    try {
      await _copyFromAssets(path);
      print('Database successfully synced from assets');
    } catch (e) {
      print('Error syncing database from assets: $e');
      rethrow;
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Robustly check for is_purchased column
    final columnCheck = await db.rawQuery('PRAGMA table_info(bah_buildings)');
    final hasIsPurchased = columnCheck.any((column) => column['name'] == 'is_purchased');
    
    if (!hasIsPurchased) {
      try {
        await db.execute('ALTER TABLE bah_buildings ADD COLUMN is_purchased INTEGER DEFAULT 0');
      } catch (e) {
        print('Error adding is_purchased column: $e');
      }
    }

    if (oldVersion < 24) {
      try {
        await db.execute('ALTER TABLE bah_stations ADD COLUMN is_unbuyable INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 23) {
      try {
        await db.execute('ALTER TABLE bah_stations ADD COLUMN allows_tax INTEGER DEFAULT 1');
      } catch (_) {}
    }
    if (oldVersion < 22) {
      try {
        await db.execute('ALTER TABLE bah_stations ADD COLUMN era TEXT DEFAULT "none"');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE bah_stations ADD COLUMN has_tax INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE bah_stations ADD COLUMN tax_amount REAL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE bah_buildings ADD COLUMN is_purchased INTEGER DEFAULT 0');
      } catch (_) {}
    }
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
    if (oldVersion < 18) {
      try {
        await db.execute(
          'ALTER TABLE bah_settings ADD COLUMN salary_per_lap REAL DEFAULT 200',
        );
        await db.execute(
          'ALTER TABLE bah_settings ADD COLUMN win_points INTEGER DEFAULT 50',
        );
      } catch (e) {
        // Already exists or ignore
      }
    }
    if (oldVersion < 21) {
      await db.execute('CREATE TABLE IF NOT EXISTS bah_templates (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)');
      
      try {
        await db.execute('ALTER TABLE bah_stations ADD COLUMN template_id INTEGER');
      } catch (_) {}
      
      try {
        await db.execute('ALTER TABLE bah_cards ADD COLUMN template_id INTEGER');
      } catch (_) {}
      
      try {
        await db.execute('ALTER TABLE bah_settings ADD COLUMN active_template_id INTEGER');
      } catch (_) {}

      // Create initial template and migrate data if bah_templates is empty
      final templates = await db.query('bah_templates', limit: 1);
      if (templates.isEmpty) {
        int templateId = await db.insert('bah_templates', {'id': 1, 'name': 'القالب الديني (إفتراضي)'});
        await db.update('bah_stations', {'template_id': templateId});
        await db.update('bah_cards', {'template_id': templateId});
        await db.update('bah_settings', {'active_template_id': templateId});
      }
    }

    if (oldVersion < 26) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bah_game_state (
            id INTEGER PRIMARY KEY DEFAULT 1,
            state_json TEXT
          )
        ''');
      } catch (_) {}
    }
    
    if (oldVersion < 28) {
      // Force re-seed default Bank Al Haz data to apply "Al-Majmaa Al-Yahudi" and building restrictions
      await BankAlHazDefaultData.seed(db, force: true);
    }
    
    if (oldVersion < 19) {
      await BankAlHazDefaultData.seed(db);
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
        base_rent REAL DEFAULT 0,
        template_id INTEGER,
        era TEXT DEFAULT 'none',
        has_tax INTEGER DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        allows_tax INTEGER DEFAULT 1,
        is_unbuyable INTEGER DEFAULT 0
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
        is_purchased INTEGER DEFAULT 0,
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
        target_station_name TEXT,
        template_id INTEGER
      )
    ''');

    // 4. Game Settings (Singleton)
    await db.execute('''
      CREATE TABLE bah_settings (
        id INTEGER (1) PRIMARY KEY DEFAULT 1,
        initial_money REAL DEFAULT 1500.0,
        win_condition TEXT DEFAULT 'rounds',
        win_criteria TEXT DEFAULT 'cumulativeValue',
        max_rounds INTEGER DEFAULT 10,
        max_time_minutes INTEGER DEFAULT 30,
        salary_per_lap REAL DEFAULT 200.0,
        win_points INTEGER DEFAULT 50,
        active_template_id INTEGER
      )
    ''');

    // 5. Templates table
    await db.execute('''CREATE TABLE bah_templates (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT
    )''');

    // 6. Game State Persistence
    await db.execute('''
      CREATE TABLE bah_game_state (
        id INTEGER PRIMARY KEY DEFAULT 1,
        state_json TEXT
      )
    ''');

    // Insert default settings if not exists
    await db.insert('bah_settings', {
      'id': 1,
      'initial_money': 1500.0,
      'win_condition': 'rounds',
      'win_criteria': 'cumulativeValue',
      'max_rounds': 10,
      'max_time_minutes': 30,
      'salary_per_lap': 200.0,
      'win_points': 50,
      'active_template_id': 1,
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

    // Initial Seeding
    await BankAlHazDefaultData.seed(db);

    // Categories are now strictly derived from user imports or Bank Al Haz setup
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getApplicationDocumentsDirectory();
    return join(dbPath.path, 'games.db');
  }

  Future<File> getDatabaseFile() async {
    return File(await getDatabasePath());
  }

  Future<void> restoreFromPath(String sourcePath) async {
    await close();
    final targetPath = await getDatabasePath();
    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
  }
}
