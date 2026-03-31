// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'penalty_shootout_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PenaltyShootout)
final penaltyShootoutProvider = PenaltyShootoutProvider._();

final class PenaltyShootoutProvider
    extends $NotifierProvider<PenaltyShootout, PenaltyShootoutState> {
  PenaltyShootoutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'penaltyShootoutProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$penaltyShootoutHash();

  @$internal
  @override
  PenaltyShootout create() => PenaltyShootout();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PenaltyShootoutState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PenaltyShootoutState>(value),
    );
  }
}

String _$penaltyShootoutHash() => r'a2138b062eedf566d9b708520b7148c4221287ea';

abstract class _$PenaltyShootout extends $Notifier<PenaltyShootoutState> {
  PenaltyShootoutState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PenaltyShootoutState, PenaltyShootoutState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PenaltyShootoutState, PenaltyShootoutState>,
              PenaltyShootoutState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
