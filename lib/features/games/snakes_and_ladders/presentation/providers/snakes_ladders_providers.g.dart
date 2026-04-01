// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snakes_ladders_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SnakesLaddersGame)
final snakesLaddersGameProvider = SnakesLaddersGameProvider._();

final class SnakesLaddersGameProvider
    extends $NotifierProvider<SnakesLaddersGame, SnakesLaddersState> {
  SnakesLaddersGameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'snakesLaddersGameProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$snakesLaddersGameHash();

  @$internal
  @override
  SnakesLaddersGame create() => SnakesLaddersGame();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SnakesLaddersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SnakesLaddersState>(value),
    );
  }
}

String _$snakesLaddersGameHash() => r'cbbde54bcf373b80890a495a2b656a711ac5db6c';

abstract class _$SnakesLaddersGame extends $Notifier<SnakesLaddersState> {
  SnakesLaddersState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SnakesLaddersState, SnakesLaddersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SnakesLaddersState, SnakesLaddersState>,
              SnakesLaddersState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
