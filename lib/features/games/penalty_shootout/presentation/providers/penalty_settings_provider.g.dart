// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'penalty_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PenaltySettings)
final penaltySettingsProvider = PenaltySettingsProvider._();

final class PenaltySettingsProvider
    extends $AsyncNotifierProvider<PenaltySettings, Map<String, dynamic>> {
  PenaltySettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'penaltySettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$penaltySettingsHash();

  @$internal
  @override
  PenaltySettings create() => PenaltySettings();
}

String _$penaltySettingsHash() => r'12497044bb2bb027fa14c7e76e047ca14d273b46';

abstract class _$PenaltySettings extends $AsyncNotifier<Map<String, dynamic>> {
  FutureOr<Map<String, dynamic>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, dynamic>>, Map<String, dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>>,
                Map<String, dynamic>
              >,
              AsyncValue<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
