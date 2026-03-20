// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'under_pressure_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UnderPressure)
final underPressureProvider = UnderPressureProvider._();

final class UnderPressureProvider
    extends $NotifierProvider<UnderPressure, UnderPressureState> {
  UnderPressureProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'underPressureProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$underPressureHash();

  @$internal
  @override
  UnderPressure create() => UnderPressure();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UnderPressureState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UnderPressureState>(value),
    );
  }
}

String _$underPressureHash() => r'8434d5e5bfae364b5074c1109eedadb42072eca2';

abstract class _$UnderPressure extends $Notifier<UnderPressureState> {
  UnderPressureState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UnderPressureState, UnderPressureState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UnderPressureState, UnderPressureState>,
              UnderPressureState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
