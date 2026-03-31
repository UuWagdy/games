import 'dart:convert';
import 'dart:typed_data';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../../../../core/database/database_service.dart';
import 'package:games/core/utils/arabic_utils.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<Category>> getCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.*, COUNT(qc.question_id) as questions_count
      FROM categories c
      LEFT JOIN question_categories qc ON c.id = qc.category_id
      GROUP BY c.id
    ''');

    return maps
        .map(
          (m) => Category(
            id: m['id'] as int?,
            name: m['name'] as String? ?? '',
            questionsCount: m['questions_count'] as int? ?? 0,
          ),
        )
        .toList();
  }

  @override
  Future<int> addCategory(String name) async {
    final db = await _dbService.database;
    return await db.insert('categories', {'name': name});
  }

  @override
  Future<void> updateCategory(Category category) async {
    final db = await _dbService.database;
    await db.update(
      'categories',
      {'name': category.name},
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // 1. Delete the links for this category
      await txn.delete('question_categories', where: 'category_id = ?', whereArgs: [id]);
      
      // 2. Delete the category itself
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
      
      // Note: We no longer delete questions that were in this category. 
      // They will now appear as "Without Category" unless they belong to other categories.
    });
  }

  @override
  Future<List<Question>> getQuestions(int? categoryId) async {
    final db = await _dbService.database;

    String query = '''
      SELECT q.*, GROUP_CONCAT(qc.category_id) as category_ids, GROUP_CONCAT(CASE WHEN qc.is_used = 1 THEN qc.category_id ELSE NULL END) as used_category_ids
      FROM questions q
      LEFT JOIN question_categories qc ON q.id = qc.question_id
    ''';

    if (categoryId != null) {
      query += ' WHERE qc.category_id = $categoryId';
    }

    query += ' GROUP BY q.id ORDER BY q.id DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);

    return List.generate(maps.length, (i) {
      final catIdsStr = maps[i]['category_ids'] as String?;
      final usedCatIdsStr = maps[i]['used_category_ids'] as String?;

      final typeStr = maps[i]['type'] as String? ?? 'essay';
      final type = QuestionType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => QuestionType.essay,
      );

      final categoryIds = (catIdsStr != null && catIdsStr.isNotEmpty)
          ? catIdsStr
                .split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList()
          : <int>[];
      final usedInCategoryIds =
          (usedCatIdsStr != null && usedCatIdsStr.isNotEmpty)
          ? usedCatIdsStr
                .split(',')
                .where((s) => s.isNotEmpty)
                .map(int.parse)
                .toList()
          : <int>[];

      return Question(
        id: maps[i]['id'] as int?,
        text: maps[i]['text'] as String? ?? '',
        answer: maps[i]['answer'] as String? ?? '',
        type: type,
        isMultiple: maps[i]['is_multiple'] == 1,
        imagePath: maps[i]['image_path'] as String?,
        imageData: maps[i]['image_data'] as Uint8List?,
        tfValue: maps[i]['tf_value'] == null
            ? null
            : (maps[i]['tf_value'] == 1),
        options: maps[i]['options_json'] != null
            ? List<String>.from(jsonDecode(maps[i]['options_json'] as String))
            : null,
        correctOptionIndices: maps[i]['correct_options_json'] != null
            ? List<int>.from(
                jsonDecode(maps[i]['correct_options_json'] as String),
              )
            : null,
        gridData: maps[i]['grid_data_json'] != null
            ? jsonDecode(maps[i]['grid_data_json'] as String)
                  as Map<String, dynamic>
            : null,
        categoryIds: categoryIds,
        usedInCategoryIds: usedInCategoryIds,
      );
    });
  }

  @override
  Future<int> addQuestion(Question question) async {
    final db = await _dbService.database;
    int questionId = await db.insert('questions', {
      'text': question.text,
      'answer': question.answer,
      'type': question.type.name,
      'image_path': question.imagePath,
      'image_data': question.imageData,
      'is_multiple': question.isMultiple ? 1 : 0,
      'tf_value': question.tfValue == null ? null : (question.tfValue! ? 1 : 0),
      'options_json': question.options != null
          ? jsonEncode(question.options)
          : null,
      'correct_options_json': question.correctOptionIndices != null
          ? jsonEncode(question.correctOptionIndices)
          : null,
      'grid_data_json': question.gridData != null
          ? jsonEncode(question.gridData)
          : null,
    });

    for (var catId in question.categoryIds) {
      await db.insert('question_categories', {
        'question_id': questionId,
        'category_id': catId,
        'is_used': question.usedInCategoryIds.contains(catId) ? 1 : 0,
      });
    }
    return questionId;
  }

  @override
  Future<void> updateQuestion(Question question) async {
    final db = await _dbService.database;
    await db.update(
      'questions',
      {
        'text': question.text,
        'answer': question.answer,
        'type': question.type.name,
        'image_path': question.imagePath,
        'image_data': question.imageData,
        'is_multiple': question.isMultiple ? 1 : 0,
        'tf_value': question.tfValue == null
            ? null
            : (question.tfValue! ? 1 : 0),
        'options_json': question.options != null
            ? jsonEncode(question.options)
            : null,
        'correct_options_json': question.correctOptionIndices != null
            ? jsonEncode(question.correctOptionIndices)
            : null,
        'grid_data_json': question.gridData != null
            ? jsonEncode(question.gridData)
            : null,
      },
      where: 'id = ?',
      whereArgs: [question.id],
    );

    // Sync categories
    await db.delete(
      'question_categories',
      where: 'question_id = ?',
      whereArgs: [question.id],
    );
    for (var catId in question.categoryIds) {
      await db.insert('question_categories', {
        'question_id': question.id,
        'category_id': catId,
        'is_used': question.usedInCategoryIds.contains(catId) ? 1 : 0,
      });
    }
  }

  @override
  Future<void> deleteQuestion(int id) async {
    final db = await _dbService.database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'question_categories',
      where: 'question_id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> setQuestionUsed(int id, bool used, {int? categoryId}) async {
    final db = await _dbService.database;
    if (categoryId != null) {
      // Per Category
      await db.update(
        'question_categories',
        {'is_used': used ? 1 : 0},
        where: 'question_id = ? AND category_id = ?',
        whereArgs: [id, categoryId],
      );
    } else {
      // Universal (if categoryId is null, we assume universal for all linked categories)
      await db.update(
        'question_categories',
        {'is_used': used ? 1 : 0},
        where: 'question_id = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<void> resetAllQuestionsUsed() async {
    final db = await _dbService.database;
    await db.update('question_categories', {'is_used': 0});
  }

  @override
  Future<int> removeDuplicateQuestions() async {
    final db = await _dbService.database;
    
    // 1. Find duplicate questions by text
    final List<Map<String, dynamic>> duplicates = await db.rawQuery('''
      SELECT text, MIN(id) as keep_id, COUNT(*) as count
      FROM questions
      GROUP BY text
      HAVING count > 1
    ''');

    int deletedCount = 0;
    
    await db.transaction((txn) async {
      for (var row in duplicates) {
        final String text = row['text'] as String;
        final int keepId = row['keep_id'] as int;
        
        // Delete all BUT the one we want to keep
        final deleted = await txn.delete(
          'questions',
          where: 'text = ? AND id != ?',
          whereArgs: [text, keepId],
        );
        deletedCount += deleted;
      }
    });
    
    return deletedCount;
  }

  @override
  Future<int> removeDuplicateCategories() async {
    final db = await _dbService.database;
    
    // 1. Find duplicate categories by name
    final List<Map<String, dynamic>> duplicates = await db.rawQuery('''
      SELECT name, MIN(id) as keep_id, COUNT(*) as count
      FROM categories
      GROUP BY name
      HAVING count > 1
    ''');

    int deletedCount = 0;
    
    await db.transaction((txn) async {
      for (var row in duplicates) {
        final String name = row['name'] as String;
        final int keepId = row['keep_id'] as int;
        
        // Find IDs to delete
        final List<Map<String, dynamic>> toDelete = await txn.query(
          'categories',
          columns: ['id'],
          where: 'name = ? AND id != ?',
          whereArgs: [name, keepId],
        );
        
        for (var d in toDelete) {
          final int deleteId = d['id'] as int;
          
          // Re-link questions to Category keepId if they were linked to deleteId
          // BUT delete links if question already exists in keepId
          await txn.rawDelete('''
            DELETE FROM question_categories
            WHERE category_id = ? 
            AND question_id IN (SELECT question_id FROM question_categories WHERE category_id = ?)
          ''', [deleteId, keepId]);

          await txn.rawUpdate('''
            UPDATE question_categories
            SET category_id = ?
            WHERE category_id = ?
          ''', [keepId, deleteId]);
          
          final deleted = await txn.delete(
            'categories',
            where: 'id = ?',
            whereArgs: [deleteId],
          );
          deletedCount += deleted;
        }
      }
    });
    
    return deletedCount;
  }

  @override
  Future<Category?> getCategoryByName(String name) async {
    final categories = await getCategories();
    final normalizedSearch = ArabicUtils.normalize(name);
    for (var cat in categories) {
      if (ArabicUtils.normalize(cat.name) == normalizedSearch) {
        return cat;
      }
    }
    return null;
  }

  @override
  Future<void> deleteAllCategories() async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      await txn.delete('question_categories');
      await txn.delete('categories');
      await txn.delete('questions');
    });
  }
}
