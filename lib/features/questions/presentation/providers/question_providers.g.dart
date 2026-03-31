// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(questionRepository)
final questionRepositoryProvider = QuestionRepositoryProvider._();

final class QuestionRepositoryProvider
    extends
        $FunctionalProvider<
          QuestionRepository,
          QuestionRepository,
          QuestionRepository
        >
    with $Provider<QuestionRepository> {
  QuestionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'questionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$questionRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuestionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  QuestionRepository create(Ref ref) {
    return questionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuestionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuestionRepository>(value),
    );
  }
}

String _$questionRepositoryHash() =>
    r'8ff1a3ba34eb6b2f07f8b95ae8ebdb98f50a3aa6';

@ProviderFor(Categories)
final categoriesProvider = CategoriesProvider._();

final class CategoriesProvider
    extends $AsyncNotifierProvider<Categories, List<Category>> {
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  Categories create() => Categories();
}

String _$categoriesHash() => r'aa01399196a47c159263199e320aa5c66588ec43';

abstract class _$Categories extends $AsyncNotifier<List<Category>> {
  FutureOr<List<Category>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Category>>, List<Category>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Category>>, List<Category>>,
              AsyncValue<List<Category>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Questions)
final questionsProvider = QuestionsFamily._();

final class QuestionsProvider
    extends $AsyncNotifierProvider<Questions, List<Question>> {
  QuestionsProvider._({
    required QuestionsFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'questionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$questionsHash();

  @override
  String toString() {
    return r'questionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Questions create() => Questions();

  @override
  bool operator ==(Object other) {
    return other is QuestionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$questionsHash() => r'cb742f8c0e62ffb07ddd639baacd3ed1d4f49c5e';

final class QuestionsFamily extends $Family
    with
        $ClassFamilyOverride<
          Questions,
          AsyncValue<List<Question>>,
          List<Question>,
          FutureOr<List<Question>>,
          int?
        > {
  QuestionsFamily._()
    : super(
        retry: null,
        name: r'questionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  QuestionsProvider call(int? categoryId) =>
      QuestionsProvider._(argument: categoryId, from: this);

  @override
  String toString() => r'questionsProvider';
}

abstract class _$Questions extends $AsyncNotifier<List<Question>> {
  late final _$args = ref.$arg as int?;
  int? get categoryId => _$args;

  FutureOr<List<Question>> build(int? categoryId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Question>>, List<Question>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Question>>, List<Question>>,
              AsyncValue<List<Question>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
