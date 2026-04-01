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
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$teamsListHash();

  @$internal
  @override
  TeamsList create() => TeamsList();
}

String _$teamsListHash() => r'0a4d5e3afa39eab7ffa59880161368cc8dd5fd14';

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

String _$currentTeamIndexHash() => r'25e72513a0fb47967bbbd27630ddbe7c107f0b0b';

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

@ProviderFor(scoreLogs)
final scoreLogsProvider = ScoreLogsFamily._();

final class ScoreLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ScoreLog>>,
          List<ScoreLog>,
          FutureOr<List<ScoreLog>>
        >
    with $FutureModifier<List<ScoreLog>>, $FutureProvider<List<ScoreLog>> {
  ScoreLogsProvider._({
    required ScoreLogsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'scoreLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scoreLogsHash();

  @override
  String toString() {
    return r'scoreLogsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ScoreLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ScoreLog>> create(Ref ref) {
    final argument = this.argument as int;
    return scoreLogs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ScoreLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scoreLogsHash() => r'80c36f6d5b1712021e790567bd3cdbd3c5f87a26';

final class ScoreLogsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ScoreLog>>, int> {
  ScoreLogsFamily._()
    : super(
        retry: null,
        name: r'scoreLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ScoreLogsProvider call(int teamId) =>
      ScoreLogsProvider._(argument: teamId, from: this);

  @override
  String toString() => r'scoreLogsProvider';
}
