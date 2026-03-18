import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const nullableIntegerType = 'INTEGER';

    // Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType
      )
    ''');

    // Questions Table
    await db.execute('''
      CREATE TABLE questions (
        id $idType,
        text $textType,
        answer $textType,
        category_id $integerType,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Teams Table
    await db.execute('''
      CREATE TABLE teams (
        id $idType,
        name $textType,
        score $integerType DEFAULT 0,
        players_count $integerType DEFAULT 0
      )
    ''');

    // Wheel Segments Table
    await db.execute('''
      CREATE TABLE wheel_segments (
        id $idType,
        text $textType,
        points $integerType,
        is_question INTEGER DEFAULT 0,
        category_id $nullableIntegerType,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');
    
    // Seed data
    await db.insert('categories', {'name': 'الكتاب المقدس'});
    await db.insert('categories', {'name': 'معلومات عامة'});
    await db.insert('categories', {'name': 'شخصيات'});

    // Seed Wheel Segments
    await db.insert('wheel_segments', {'text': '10 نقاط', 'points': 10, 'is_question': 0});
    await db.insert('wheel_segments', {'text': '20 نقطة', 'points': 20, 'is_question': 0});
    await db.insert('wheel_segments', {'text': 'سؤال سهل', 'points': 5, 'is_question': 1, 'category_id': 1});
    await db.insert('wheel_segments', {'text': 'سؤال صعب', 'points': 15, 'is_question': 1, 'category_id': 1});
    await db.insert('wheel_segments', {'text': 'خسارة 5 نقاط', 'points': -5, 'is_question': 0});
  }

  Future<void> close() async {
    final db = await _database;
    if (db != null) {
      await db.close();
    }
  }
}
