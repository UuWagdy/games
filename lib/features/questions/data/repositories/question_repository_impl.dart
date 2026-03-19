import 'dart:convert';
import 'dart:typed_data';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../models/category_model.dart';
import '../../../../core/database/database_service.dart';

class QuestionRepositoryImpl implements QuestionRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<Category>> getCategories() async {
    final db = await _dbService.database;
    final result = await db.query('categories');
    return result.map((json) {
      final model = CategoryModel.fromJson(json);
      return Category(id: model.id, name: model.name);
    }).toList();
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
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
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
      final type = QuestionType.values.firstWhere((e) => e.name == typeStr, orElse: () => QuestionType.essay);

      final categoryIds = (catIdsStr != null && catIdsStr.isNotEmpty)
          ? catIdsStr.split(',').where((s) => s.isNotEmpty).map(int.parse).toList()
          : <int>[];
      final usedInCategoryIds = (usedCatIdsStr != null && usedCatIdsStr.isNotEmpty)
          ? usedCatIdsStr.split(',').where((s) => s.isNotEmpty).map(int.parse).toList()
          : <int>[];

      return Question(
        id: maps[i]['id'] as int?,
        text: maps[i]['text'] as String? ?? '',
        answer: maps[i]['answer'] as String? ?? '',
        type: type,
        isMultiple: maps[i]['is_multiple'] == 1,
        imagePath: maps[i]['image_path'] as String?,
        imageData: maps[i]['image_data'] as Uint8List?,
        tfValue: maps[i]['tf_value'] == null ? null : (maps[i]['tf_value'] == 1),
        options: maps[i]['options_json'] != null ? List<String>.from(jsonDecode(maps[i]['options_json'] as String)) : null,
        correctOptionIndices: maps[i]['correct_options_json'] != null ? List<int>.from(jsonDecode(maps[i]['correct_options_json'] as String)) : null,
        gridData: maps[i]['grid_data_json'] != null ? jsonDecode(maps[i]['grid_data_json'] as String) as Map<String, dynamic> : null,
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
      'options_json': question.options != null ? jsonEncode(question.options) : null,
      'correct_options_json': question.correctOptionIndices != null ? jsonEncode(question.correctOptionIndices) : null,
      'grid_data_json': question.gridData != null ? jsonEncode(question.gridData) : null,
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
        'tf_value': question.tfValue == null ? null : (question.tfValue! ? 1 : 0),
        'options_json': question.options != null ? jsonEncode(question.options) : null,
        'correct_options_json': question.correctOptionIndices != null ? jsonEncode(question.correctOptionIndices) : null,
        'grid_data_json': question.gridData != null ? jsonEncode(question.gridData) : null,
      },
      where: 'id = ?',
      whereArgs: [question.id],
    );

    // Sync categories
    await db.delete('question_categories', where: 'question_id = ?', whereArgs: [question.id]);
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
    await db.delete('question_categories', where: 'question_id = ?', whereArgs: [id]);
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
}
