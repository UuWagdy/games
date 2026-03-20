import 'dart:typed_data';
import 'package:games/core/database/database_service.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../../domain/repositories/bank_al_haz_repository.dart';

class BankAlHazRepositoryImpl implements BankAlHazRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  @override
  Future<List<BankAlHazTemplate>> getTemplates() async {
    final db = await _dbService.database;
    final maps = await db.query('bah_templates');
    return maps.map((m) => BankAlHazTemplate(
      id: m['id'] as int?,
      name: m['name'] as String? ?? 'قالب بدون اسم',
    )).toList();
  }

  @override
  Future<int> saveTemplate(BankAlHazTemplate template) async {
    final db = await _dbService.database;
    final row = {'name': template.name};
    if (template.id != null) {
      await db.update('bah_templates', row, where: 'id = ?', whereArgs: [template.id]);
      return template.id!;
    } else {
      return await db.insert('bah_templates', row);
    }
  }

  @override
  Future<void> deleteTemplate(int id) async {
    final db = await _dbService.database;
    await db.delete('bah_templates', where: 'id = ?', whereArgs: [id]);
    await db.delete('bah_stations', where: 'template_id = ?', whereArgs: [id]);
    await db.delete('bah_cards', where: 'template_id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Station>> getStations({int? templateId}) async {
    try {
      final db = await _dbService.database;
      
      int targetTemplateId = templateId ?? (await getSettings()).activeTemplateId ?? 1;
      
      final stationMaps = await db.query(
        'bah_stations',
        where: 'template_id = ?',
        whereArgs: [targetTemplateId],
      );
      
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
          isPurchased: (b['is_purchased'] as int? ?? 0) == 1,
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
          isUnbuyable: (map['is_unbuyable'] as int? ?? 0) == 1,
          templateId: map['template_id'] as int?,
          era: Era.values.firstWhere(
            (e) => e.name == map['era'], 
            orElse: () => Era.none
          ),
          hasTax: (map['has_tax'] as int? ?? 0) == 1,
          taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
          allowsTax: (map['allows_tax'] as int? ?? 1) == 1,
        ));
      }
      return stations;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<int> saveStation(Station station, {int? templateId}) async {
    final db = await _dbService.database;
    int targetTemplateId = templateId ?? station.templateId ?? (await getSettings()).activeTemplateId ?? 1;

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
      'is_unbuyable': station.isUnbuyable ? 1 : 0,
      'template_id': targetTemplateId,
      'era': station.era.name,
      'has_tax': station.hasTax ? 1 : 0,
      'tax_amount': station.taxAmount,
      'allows_tax': station.allowsTax ? 1 : 0,
    };
    if (station.id != null) {
      await db.update('bah_stations', row, where: 'id = ?', whereArgs: [station.id]);
      return station.id!;
    } else {
      return await db.insert('bah_stations', row);
    }
  }

  @override
  Future<void> deleteAllStations({int? templateId}) async {
    final db = await _dbService.database;
    int targetTemplateId = templateId ?? (await getSettings()).activeTemplateId ?? 1;
    
    // We need to delete buildings of stations belonging to this template
    final stationIds = await db.query('bah_stations', columns: ['id'], where: 'template_id = ?', whereArgs: [targetTemplateId]);
    for (var sid in stationIds) {
      await db.delete('bah_buildings', where: 'station_id = ?', whereArgs: [sid['id']]);
    }
    await db.delete('bah_stations', where: 'template_id = ?', whereArgs: [targetTemplateId]);
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
      'is_purchased': building.isPurchased ? 1 : 0,
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
  Future<void> addStation(Station station, {int? templateId}) async {
    final id = await saveStation(station, templateId: templateId);
    final db = await _dbService.database;
    for (var b in station.buildings) {
      await db.insert('bah_buildings', {
        'station_id': id,
        'name': b.name,
        'buy_price': b.buyPrice,
        'additional_rent': b.additionalRent,
        'is_purchased': b.isPurchased ? 1 : 0,
      });
    }
  }

  @override
  Future<List<BankAlHazCard>> getCards({int? templateId}) async {
    try {
      final db = await _dbService.database;
      int targetTemplateId = templateId ?? (await getSettings()).activeTemplateId ?? 1;

      final maps = await db.query(
        'bah_cards',
        where: 'template_id = ?',
        whereArgs: [targetTemplateId],
      );
      
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
        templateId: m['template_id'] as int?,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addCard(BankAlHazCard card, {int? templateId}) async {
    await saveCard(card, templateId: templateId);
  }

  @override
  Future<void> deleteAllCards({int? templateId}) async {
    final db = await _dbService.database;
    int targetTemplateId = templateId ?? (await getSettings()).activeTemplateId ?? 1;
    await db.delete('bah_cards', where: 'template_id = ?', whereArgs: [targetTemplateId]);
  }

  @override
  Future<void> deleteCard(int id) async {
    final db = await _dbService.database;
    await db.delete('bah_cards', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> saveCard(BankAlHazCard card, {int? templateId}) async {
    final db = await _dbService.database;
    int targetTemplateId = templateId ?? card.templateId ?? (await getSettings()).activeTemplateId ?? 1;

    final row = {
      'title': card.title,
      'description': card.description,
      'image_path': card.imagePath,
      'type': card.type,
      'effect_type': card.effectType.name,
      'effect_value': card.effectValue,
      'target_station_name': card.targetStationName,
      'template_id': targetTemplateId,
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
          salaryPerLap: (m['salary_per_lap'] as num?)?.toDouble() ?? 200.0,
          winPoints: (m['win_points'] as num?)?.toInt() ?? 50,
          activeTemplateId: m['active_template_id'] as int?,
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
      'salary_per_lap': settings.salaryPerLap,
      'win_points': settings.winPoints,
      'active_template_id': settings.activeTemplateId,
    };
    await db.update('bah_settings', row, where: 'id = 1');
  }
}
