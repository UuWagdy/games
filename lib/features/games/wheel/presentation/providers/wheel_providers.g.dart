// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wheel_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(wheelRepository)
final wheelRepositoryProvider = WheelRepositoryProvider._();

final class WheelRepositoryProvider
    extends
        $FunctionalProvider<WheelRepository, WheelRepository, WheelRepository>
    with $Provider<WheelRepository> {
  WheelRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wheelRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wheelRepositoryHash();

  @$internal
  @override
  $ProviderElement<WheelRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WheelRepository create(Ref ref) {
    return wheelRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WheelRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WheelRepository>(value),
    );
  }
}

String _$wheelRepositoryHash() => r'5ea0d28c35a46e13fec8b608b8b228ff12dafab9';

@ProviderFor(WheelSegments)
final wheelSegmentsProvider = WheelSegmentsProvider._();

final class WheelSegmentsProvider
    extends $AsyncNotifierProvider<WheelSegments, List<WheelSegment>> {
  WheelSegmentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wheelSegmentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wheelSegmentsHash();

  @$internal
  @override
  WheelSegments create() => WheelSegments();
}

String _$wheelSegmentsHash() => r'c0501f1aecb8b6eafc117f4995641ac2e900f6a4';

abstract class _$WheelSegments extends $AsyncNotifier<List<WheelSegment>> {
  FutureOr<List<WheelSegment>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<WheelSegment>>, List<WheelSegment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<WheelSegment>>, List<WheelSegment>>,
              AsyncValue<List<WheelSegment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
