import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/question.dart';
import '../../data/repositories/question_repository_impl.dart';
import '../../domain/repositories/question_repository.dart';

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
    ref.invalidateSelf();
  }

  Future<void> deleteQuestion(int id) async {
    await ref.read(questionRepositoryProvider).deleteQuestion(id);
    ref.invalidateSelf();
  }
}
