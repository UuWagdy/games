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
  }

  Future<void> updateCategory(Category category) async {
    await ref.read(questionRepositoryProvider).updateCategory(category);
    ref.invalidateSelf();
  }

  Future<void> deleteCategory(int id) async {
    await ref.read(questionRepositoryProvider).deleteCategory(id);
    ref.invalidateSelf();
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
  }

  Future<void> updateQuestion(Question question) async {
    await ref.read(questionRepositoryProvider).updateQuestion(question);
    ref.invalidate(questionsProvider);
  }

  Future<void> deleteQuestion(int id) async {
    await ref.read(questionRepositoryProvider).deleteQuestion(id);
    ref.invalidate(questionsProvider);
  }

  Future<void> setQuestionUsed(int id, bool used, {int? categoryId}) async {
    await ref.read(questionRepositoryProvider).setQuestionUsed(id, used, categoryId: categoryId);
    ref.invalidate(questionsProvider);
  }

  Future<void> resetAllQuestionsUsed() async {
    await ref.read(questionRepositoryProvider).resetAllQuestionsUsed();
    ref.invalidate(questionsProvider);
  }
}
