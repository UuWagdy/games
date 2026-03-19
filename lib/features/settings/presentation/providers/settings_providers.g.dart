// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GeneralSettings)
final generalSettingsProvider = GeneralSettingsProvider._();

final class GeneralSettingsProvider
    extends $AsyncNotifierProvider<GeneralSettings, Map<String, dynamic>> {
  GeneralSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generalSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generalSettingsHash();

  @$internal
  @override
  GeneralSettings create() => GeneralSettings();
}

String _$generalSettingsHash() => r'6a3bdf732d5ad2abeccbc9371b8df0f0f3f76b5b';

abstract class _$GeneralSettings extends $AsyncNotifier<Map<String, dynamic>> {
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
