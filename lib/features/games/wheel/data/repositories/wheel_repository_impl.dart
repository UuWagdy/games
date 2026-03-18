import 'package:games/core/database/database_service.dart';
import 'package:games/features/games/wheel/data/models/wheel_segment_model.dart';
import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';
import 'package:games/features/games/wheel/domain/repositories/wheel_repository.dart';

class WheelRepositoryImpl implements WheelRepository {
  final DatabaseService _dbService = DatabaseService();

  @override
  Future<List<WheelSegment>> getSegments() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.query('wheel_segments');
    
    return result.map((json) {
      final model = WheelSegmentModel.fromJson(json);
      return WheelSegment(
        id: model.id,
        text: model.text,
        points: model.points,
        isQuestion: model.isQuestion,
        categoryId: model.categoryId,
      );
    }).toList();
  }

  @override
  Future<void> addSegment(WheelSegment segment) async {
    final db = await _dbService.database;
    final model = WheelSegmentModel(
      text: segment.text,
      points: segment.points,
      isQuestion: segment.isQuestion,
      categoryId: segment.categoryId,
    );
    await db.insert('wheel_segments', model.toJson());
  }

  @override
  Future<void> updateSegment(WheelSegment segment) async {
    final db = await _dbService.database;
    final model = WheelSegmentModel(
      id: segment.id,
      text: segment.text,
      points: segment.points,
      isQuestion: segment.isQuestion,
      categoryId: segment.categoryId,
    );
    await db.update(
      'wheel_segments',
      model.toJson(),
      where: 'id = ?',
      whereArgs: [segment.id],
    );
  }

  @override
  Future<void> deleteSegment(int id) async {
    final db = await _dbService.database;
    await db.delete(
      'wheel_segments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
