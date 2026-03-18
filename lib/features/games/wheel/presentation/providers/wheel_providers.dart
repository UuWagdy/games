import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';
import 'package:games/features/games/wheel/domain/repositories/wheel_repository.dart';
import 'package:games/features/games/wheel/data/repositories/wheel_repository_impl.dart';

part 'wheel_providers.g.dart';

@riverpod
WheelRepository wheelRepository(Ref ref) {
  return WheelRepositoryImpl();
}

@riverpod
class WheelSegments extends _$WheelSegments {
  @override
  Future<List<WheelSegment>> build() async {
    return ref.read(wheelRepositoryProvider).getSegments();
  }

  Future<void> addSegment(WheelSegment segment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(wheelRepositoryProvider).addSegment(segment);
      return ref.read(wheelRepositoryProvider).getSegments();
    });
  }

  Future<void> updateSegment(WheelSegment segment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(wheelRepositoryProvider).updateSegment(segment);
      return ref.read(wheelRepositoryProvider).getSegments();
    });
  }

  Future<void> deleteSegment(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(wheelRepositoryProvider).deleteSegment(id);
      return ref.read(wheelRepositoryProvider).getSegments();
    });
  }
}
