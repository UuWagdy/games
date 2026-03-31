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

String _$generalSettingsHash() => r'292f9e5c892f325e89bb55efdef216aa98c296e4';

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

@ProviderFor(currentTheme)
final currentThemeProvider = CurrentThemeProvider._();

final class CurrentThemeProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThemeConfig>,
          ThemeConfig,
          FutureOr<ThemeConfig>
        >
    with $FutureModifier<ThemeConfig>, $FutureProvider<ThemeConfig> {
  CurrentThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentThemeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentThemeHash();

  @$internal
  @override
  $FutureProviderElement<ThemeConfig> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ThemeConfig> create(Ref ref) {
    return currentTheme(ref);
  }
}

String _$currentThemeHash() => r'ab72e31940c4e127b041f72b28d32b5e45dec5f2';
