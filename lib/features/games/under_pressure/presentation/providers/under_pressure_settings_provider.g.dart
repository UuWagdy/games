// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'under_pressure_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UnderPressureSettings)
final underPressureSettingsProvider = UnderPressureSettingsProvider._();

final class UnderPressureSettingsProvider
    extends
        $AsyncNotifierProvider<UnderPressureSettings, Map<String, dynamic>> {
  UnderPressureSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'underPressureSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$underPressureSettingsHash();

  @$internal
  @override
  UnderPressureSettings create() => UnderPressureSettings();
}

String _$underPressureSettingsHash() =>
    r'671bedf3430e8174be5ffcfc13d706058abf1080';

abstract class _$UnderPressureSettings
    extends $AsyncNotifier<Map<String, dynamic>> {
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
