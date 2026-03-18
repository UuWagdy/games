import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../domain/repositories/question_repository.dart';
import '../models/category_model.dart';
import '../models/question_model.dart';
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
    final List<Map<String, dynamic>> result;
    if (categoryId != null) {
      result = await db.query(
        'questions',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );
    } else {
      result = await db.query('questions');
    }
    return result.map((json) {
      final model = QuestionModel.fromJson(json);
      return Question(
        id: model.id,
        text: model.text,
        answer: model.answer,
        categoryId: model.categoryId,
      );
    }).toList();
  }

  @override
  Future<int> addQuestion(Question question) async {
    final db = await _dbService.database;
    return await db.insert('questions', {
      'text': question.text,
      'answer': question.answer,
      'category_id': question.categoryId,
    });
  }

  @override
  Future<void> updateQuestion(Question question) async {
    final db = await _dbService.database;
    await db.update(
      'questions',
      {
        'text': question.text,
        'answer': question.answer,
        'category_id': question.categoryId,
      },
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  @override
  Future<void> deleteQuestion(int id) async {
    final db = await _dbService.database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }
}
