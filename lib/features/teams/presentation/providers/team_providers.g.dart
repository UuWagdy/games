// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(teamRepository)
final teamRepositoryProvider = TeamRepositoryProvider._();

final class TeamRepositoryProvider
    extends $FunctionalProvider<TeamRepository, TeamRepository, TeamRepository>
    with $Provider<TeamRepository> {
  TeamRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamRepositoryHash();

  @$internal
  @override
  $ProviderElement<TeamRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TeamRepository create(Ref ref) {
    return teamRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TeamRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TeamRepository>(value),
    );
  }
}

String _$teamRepositoryHash() => r'94f95e1c5b44c442cbc38b12e393a29699e770d0';

@ProviderFor(TeamsList)
final teamsListProvider = TeamsListProvider._();

final class TeamsListProvider
    extends $AsyncNotifierProvider<TeamsList, List<Team>> {
  TeamsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'teamsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsListHash();

  @$internal
  @override
  TeamsList create() => TeamsList();
}

String _$teamsListHash() => r'205aca77a4ba80e7afb495a24de7321f04099afa';

abstract class _$TeamsList extends $AsyncNotifier<List<Team>> {
  FutureOr<List<Team>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Team>>, List<Team>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Team>>, List<Team>>,
              AsyncValue<List<Team>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CurrentTeamIndex)
final currentTeamIndexProvider = CurrentTeamIndexProvider._();

final class CurrentTeamIndexProvider
    extends $NotifierProvider<CurrentTeamIndex, int> {
  CurrentTeamIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentTeamIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentTeamIndexHash();

  @$internal
  @override
  CurrentTeamIndex create() => CurrentTeamIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$currentTeamIndexHash() => r'fed93764097f14191ae85a058ef191c3a56746ef';

abstract class _$CurrentTeamIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
