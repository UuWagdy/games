// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tic_tac_toe_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TicTacToeController)
final ticTacToeControllerProvider = TicTacToeControllerProvider._();

final class TicTacToeControllerProvider
    extends $NotifierProvider<TicTacToeController, TicTacToeState> {
  TicTacToeControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ticTacToeControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ticTacToeControllerHash();

  @$internal
  @override
  TicTacToeController create() => TicTacToeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TicTacToeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TicTacToeState>(value),
    );
  }
}

String _$ticTacToeControllerHash() =>
    r'2c73bc87e4566c4e31a57132cde553acbce412d8';

abstract class _$TicTacToeController extends $Notifier<TicTacToeState> {
  TicTacToeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TicTacToeState, TicTacToeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TicTacToeState, TicTacToeState>,
              TicTacToeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
