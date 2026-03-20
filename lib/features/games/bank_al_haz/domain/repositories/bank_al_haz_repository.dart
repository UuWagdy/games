import '../entities/bank_al_haz_entities.dart';

abstract class BankAlHazRepository {
  // Templates
  Future<List<BankAlHazTemplate>> getTemplates();
  Future<int> saveTemplate(BankAlHazTemplate template);
  Future<void> deleteTemplate(int id);

  // Stations
  Future<List<Station>> getStations({int? templateId});
  Future<int> saveStation(Station station, {int? templateId});
  Future<void> deleteStation(int id);
  Future<void> saveBuilding(Building building);
  Future<void> deleteBuilding(int id);
  Future<void> deleteAllStations({int? templateId});
  Future<void> addStation(Station station, {int? templateId});

  // Cards
  Future<List<BankAlHazCard>> getCards({int? templateId});
  Future<int> saveCard(BankAlHazCard card, {int? templateId});
  Future<void> addCard(BankAlHazCard card, {int? templateId});
  Future<void> deleteCard(int id);
  Future<void> deleteAllCards({int? templateId});

  // Settings
  Future<BankAlHazSettings> getSettings();
  Future<void> saveSettings(BankAlHazSettings settings);
}
