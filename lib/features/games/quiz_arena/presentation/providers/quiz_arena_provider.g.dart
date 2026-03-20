// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_arena_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(QuizArenaSettingsNotifier)
final quizArenaSettingsProvider = QuizArenaSettingsNotifierProvider._();

final class QuizArenaSettingsNotifierProvider
    extends $NotifierProvider<QuizArenaSettingsNotifier, QuizArenaSettings> {
  QuizArenaSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quizArenaSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quizArenaSettingsNotifierHash();

  @$internal
  @override
  QuizArenaSettingsNotifier create() => QuizArenaSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuizArenaSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuizArenaSettings>(value),
    );
  }
}

String _$quizArenaSettingsNotifierHash() =>
    r'd81cb399d3bc4586d5b1669bd1491e0df77d4cb6';

abstract class _$QuizArenaSettingsNotifier
    extends $Notifier<QuizArenaSettings> {
  QuizArenaSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QuizArenaSettings, QuizArenaSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuizArenaSettings, QuizArenaSettings>,
              QuizArenaSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(QuizArenaGame)
final quizArenaGameProvider = QuizArenaGameProvider._();

final class QuizArenaGameProvider
    extends $NotifierProvider<QuizArenaGame, QuizArenaGameState> {
  QuizArenaGameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quizArenaGameProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quizArenaGameHash();

  @$internal
  @override
  QuizArenaGame create() => QuizArenaGame();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuizArenaGameState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<QuizArenaGameState>(value),
    );
  }
}

String _$quizArenaGameHash() => r'92ace63e8855879a34c28bccadfbb13dff3386d1';

abstract class _$QuizArenaGame extends $Notifier<QuizArenaGameState> {
  QuizArenaGameState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<QuizArenaGameState, QuizArenaGameState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<QuizArenaGameState, QuizArenaGameState>,
              QuizArenaGameState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
