import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';

abstract class WheelRepository {
  Future<List<WheelSegment>> getSegments();
  Future<void> addSegment(WheelSegment segment);
  Future<void> updateSegment(WheelSegment segment);
  Future<void> deleteSegment(int id);
}
