import '../entities/question.dart';
import '../entities/category.dart';

abstract class QuestionRepository {
  Future<List<Category>> getCategories();
  Future<int> addCategory(String name);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);

  Future<List<Question>> getQuestions(int? categoryId);
  Future<int> addQuestion(Question question);
  Future<void> updateQuestion(Question question);
  Future<void> deleteQuestion(int id);
  Future<void> setQuestionUsed(int id, bool used, {int? categoryId});
  Future<void> resetAllQuestionsUsed();
  Future<int> removeDuplicateQuestions();
  Future<int> removeDuplicateCategories();
  Future<Category?> getCategoryByName(String name);
  Future<void> deleteAllCategories();
}
