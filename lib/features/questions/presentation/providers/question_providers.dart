import 'package:games/features/questions/domain/entities/question.dart';
import 'package:games/features/questions/domain/entities/category.dart';
import 'package:games/features/questions/domain/repositories/question_repository.dart';
import 'package:games/features/questions/data/repositories/question_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'question_providers.g.dart';

@riverpod
QuestionRepository questionRepository(Ref ref) {
  return QuestionRepositoryImpl();
}

@riverpod
class Categories extends _$Categories {
  @override
  Future<List<Category>> build() async {
    return ref.watch(questionRepositoryProvider).getCategories();
  }

  Future<void> addCategory(String name) async {
    await ref.read(questionRepositoryProvider).addCategory(name);
    ref.invalidateSelf();
    ref.invalidate(questionsProvider);
  }

  Future<void> updateCategory(Category category) async {
    await ref.read(questionRepositoryProvider).updateCategory(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(int id) async {
    await ref.read(questionRepositoryProvider).deleteCategory(id);
    ref.invalidateSelf();
    ref.invalidate(questionsProvider);
  }

  Future<int> removeDuplicateCategories() async {
    final count = await ref.read(questionRepositoryProvider).removeDuplicateCategories();
    ref.invalidateSelf();
    ref.invalidate(questionsProvider);
    return count;
  }

  Future<void> deleteAllCategories() async {
    await ref.read(questionRepositoryProvider).deleteAllCategories();
    ref.invalidateSelf();
    ref.invalidate(questionsProvider);
  }
}

@riverpod
class Questions extends _$Questions {
  @override
  Future<List<Question>> build(int? categoryId) async {
    return ref.watch(questionRepositoryProvider).getQuestions(categoryId);
  }

  Future<void> addQuestion(Question question) async {
    await ref.read(questionRepositoryProvider).addQuestion(question);
    ref.invalidate(questionsProvider);
    ref.invalidate(categoriesProvider);
  }

  Future<void> updateQuestion(Question question) async {
    await ref.read(questionRepositoryProvider).updateQuestion(question);
    ref.invalidate(questionsProvider);
    ref.invalidate(categoriesProvider);
  }

  Future<void> deleteQuestion(int id) async {
    await ref.read(questionRepositoryProvider).deleteQuestion(id);
    ref.invalidate(questionsProvider);
    ref.invalidate(categoriesProvider);
  }

  Future<void> setQuestionUsed(int id, bool used, {int? categoryId}) async {
    await ref.read(questionRepositoryProvider).setQuestionUsed(id, used, categoryId: categoryId);
    ref.invalidate(questionsProvider);
  }

  Future<void> resetAllQuestionsUsed() async {
    await ref.read(questionRepositoryProvider).resetAllQuestionsUsed();
    ref.invalidate(questionsProvider);
  }

  Future<int> removeDuplicateQuestions() async {
    final count = await ref.read(questionRepositoryProvider).removeDuplicateQuestions();
    ref.invalidate(questionsProvider);
    ref.invalidate(categoriesProvider);
    return count;
  }
}
