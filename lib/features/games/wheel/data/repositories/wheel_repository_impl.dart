import 'package:games/core/database/database_service.dart';
import 'package:games/features/games/wheel/data/models/wheel_segment_model.dart';
import 'package:games/features/games/wheel/domain/entities/wheel_segment.dart';
import 'package:games/features/games/wheel/domain/repositories/wheel_repository.dart';

class WheelRepositoryImpl implements WheelRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<WheelSegment>> getSegments() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.query('wheel_segments');
    
    return result.map((json) {
      final map = Map<String, dynamic>.from(json);
      map['is_question'] = map['is_question'] == 1;
      map['is_switch'] = map['is_switch'] == 1;
      map['is_joker'] = map['is_joker'] == 1;
      
      // Convert '1,2,3' to [1, 2, 3]
      final idsString = map['category_ids'] as String?;
      map['category_ids'] = idsString != null && idsString.isNotEmpty
          ? idsString.split(',').map((e) => int.parse(e)).toList()
          : [];
          
      final model = WheelSegmentModel.fromJson(map);
      return WheelSegment(
        id: model.id,
        text: model.text,
        points: model.points,
        isQuestion: model.isQuestion,
        categoryIds: model.categoryIds,
        isSwitch: model.isSwitch,
        isJoker: model.isJoker,
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
      categoryIds: segment.categoryIds,
      isSwitch: segment.isSwitch,
      isJoker: segment.isJoker,
    );
    final map = model.toJson();
    map['is_question'] = model.isQuestion ? 1 : 0;
    map['is_switch'] = model.isSwitch ? 1 : 0;
    map['is_joker'] = model.isJoker ? 1 : 0;
    // Store as '1,2,3'
    map['category_ids'] = model.categoryIds.join(',');
    await db.insert('wheel_segments', map);
  }

  @override
  Future<void> updateSegment(WheelSegment segment) async {
    final db = await _dbService.database;
    final model = WheelSegmentModel(
      id: segment.id,
      text: segment.text,
      points: segment.points,
      isQuestion: segment.isQuestion,
      categoryIds: segment.categoryIds,
      isSwitch: segment.isSwitch,
      isJoker: segment.isJoker,
    );
    final map = model.toJson();
    map['is_question'] = model.isQuestion ? 1 : 0;
    map['is_switch'] = model.isSwitch ? 1 : 0;
    map['is_joker'] = model.isJoker ? 1 : 0;
    // Store as '1,2,3'
    map['category_ids'] = model.categoryIds.join(',');
    await db.update(
      'wheel_segments',
      map,
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
