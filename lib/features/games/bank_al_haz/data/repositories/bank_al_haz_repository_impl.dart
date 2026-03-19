import 'dart:typed_data';
import 'package:games/core/database/database_service.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../../domain/repositories/bank_al_haz_repository.dart';

class BankAlHazRepositoryImpl implements BankAlHazRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<Station>> getStations() async {
    try {
      final db = await _dbService.database;
      final stationMaps = await db.query('bah_stations');
      
      List<Station> stations = [];
      for (var map in stationMaps) {
        final buildingMaps = await db.query(
          'bah_buildings',
          where: 'station_id = ?',
          whereArgs: [map['id']],
        );
        
        final buildings = buildingMaps.map((b) => Building(
          id: b['id'] as int?,
          stationId: b['station_id'] as int?,
          name: b['name'] as String? ?? '',
          buyPrice: (b['buy_price'] as num?)?.toDouble() ?? 0.0,
          additionalRent: (b['additional_rent'] as num?)?.toDouble() ?? 0.0,
        )).toList();
        
        stations.add(Station(
          id: map['id'] as int?,
          name: map['name'] as String? ?? 'محطة',
          imagePath: map['image_path'] as String?,
          imageData: map['image_data'] as Uint8List?,
          type: StationType.values.firstWhere(
            (e) => e.name == map['type'], 
            orElse: () => StationType.question
          ),
          ownerCategoryId: map['owner_category_id'] as int? ?? map['category_id'] as int?,
          passerCategoryId: map['passer_category_id'] as int?,
          requiresQuestion: (map['requires_question'] as int? ?? 1) == 1,
          cardType: map['card_type'] as String?,
          buyPrice: (map['buy_price'] as num?)?.toDouble() ?? 0.0,
          baseRent: (map['base_rent'] as num?)?.toDouble() ?? 0.0,
          buildings: buildings,
        ));
      }
      return stations;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<int> saveStation(Station station) async {
    final db = await _dbService.database;
    final row = {
      'name': station.name,
      'image_path': station.imagePath,
      'image_data': station.imageData,
      'type': station.type.name,
      'owner_category_id': station.ownerCategoryId,
      'passer_category_id': station.passerCategoryId,
      'requires_question': station.requiresQuestion ? 1 : 0,
      'card_type': station.cardType,
      'buy_price': station.buyPrice,
      'base_rent': station.baseRent,
    };
    if (station.id != null) {
      await db.update('bah_stations', row, where: 'id = ?', whereArgs: [station.id]);
      return station.id!;
    } else {
      return await db.insert('bah_stations', row);
    }
  }

  @override
  Future<void> deleteAllStations() async {
    final db = await _dbService.database;
    await db.delete('bah_stations');
    await db.delete('bah_buildings');
  }

  @override
  Future<void> deleteStation(int id) async {
    final db = await _dbService.database;
    await db.delete('bah_stations', where: 'id = ?', whereArgs: [id]);
    await db.delete('bah_buildings', where: 'station_id = ?', whereArgs: [id]);
  }

  @override
  Future<void> saveBuilding(Building building) async {
    final db = await _dbService.database;
    final row = {
      'station_id': building.stationId,
      'name': building.name,
      'buy_price': building.buyPrice,
      'additional_rent': building.additionalRent,
    };
    if (building.id != null) {
      await db.update('bah_buildings', row, where: 'id = ?', whereArgs: [building.id]);
    } else {
      await db.insert('bah_buildings', row);
    }
  }

  @override
  Future<void> deleteBuilding(int id) async {
    final db = await _dbService.database;
    await db.delete('bah_buildings', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> addStation(Station station) async {
    final id = await saveStation(station);
    final db = await _dbService.database;
    for (var b in station.buildings) {
      await db.insert('bah_buildings', {
        'station_id': id,
        'name': b.name,
        'buy_price': b.buyPrice,
        'additional_rent': b.additionalRent,
      });
    }
  }

  @override
  Future<List<BankAlHazCard>> getCards() async {
    try {
      final db = await _dbService.database;
      final maps = await db.query('bah_cards');
      return maps.map((m) => BankAlHazCard(
        id: m['id'] as int?,
        title: m['title'] as String? ?? '',
        description: m['description'] as String? ?? '',
        imagePath: m['image_path'] as String?,
        type: m['type'] as String?,
        effectType: CardEffectType.values.firstWhere(
          (e) => e.name == m['effect_type'],
          orElse: () => CardEffectType.addMoney
        ),
        effectValue: (m['effect_value'] as num?)?.toInt() ?? 0,
        targetStationName: m['target_station_name'] as String?,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addCard(BankAlHazCard card) async {
    await saveCard(card);
  }

  @override
  Future<void> deleteAllCards() async {
    final db = await _dbService.database;
    await db.delete('bah_cards');
  }

  @override
  Future<void> deleteCard(int id) async {
    final db = await _dbService.database;
    await db.delete('bah_cards', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> saveCard(BankAlHazCard card) async {
    final db = await _dbService.database;
    final row = {
      'title': card.title,
      'description': card.description,
      'image_path': card.imagePath,
      'type': card.type,
      'effect_type': card.effectType.name,
      'effect_value': card.effectValue,
      'target_station_name': card.targetStationName,
    };
    if (card.id != null) {
      await db.update('bah_cards', row, where: 'id = ?', whereArgs: [card.id]);
      return card.id!;
    } else {
      return await db.insert('bah_cards', row);
    }
  }

  @override
  Future<BankAlHazSettings> getSettings() async {
    try {
      final db = await _dbService.database;
      final maps = await db.query('bah_settings', where: 'id = 1');
      if (maps.isNotEmpty) {
        final m = maps.first;
        return BankAlHazSettings(
          initialMoney: (m['initial_money'] as num?)?.toDouble() ?? 1500.0,
          winCondition: WinningCondition.values.firstWhere(
            (e) => e.name == m['win_condition'],
            orElse: () => WinningCondition.rounds
          ),
          winCriteria: WinCriteria.values.firstWhere(
            (e) => e.name == m['win_criteria'],
            orElse: () => WinCriteria.moneyOnly
          ),
          maxRounds: (m['max_rounds'] as num?)?.toInt() ?? 10,
          maxTimeMinutes: (m['max_time_minutes'] as num?)?.toInt() ?? 30,
        );
      }
    } catch (e) {}
    return const BankAlHazSettings();
  }

  @override
  Future<void> saveSettings(BankAlHazSettings settings) async {
    final db = await _dbService.database;
    final row = {
      'initial_money': settings.initialMoney,
      'win_condition': settings.winCondition.name,
      'win_criteria': settings.winCriteria.name,
      'max_rounds': settings.maxRounds,
      'max_time_minutes': settings.maxTimeMinutes,
    };
    await db.update('bah_settings', row, where: 'id = 1');
  }
}
