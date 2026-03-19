import '../entities/bank_al_haz_entities.dart';

abstract class BankAlHazRepository {
  // Stations
  Future<List<Station>> getStations();
  Future<int> saveStation(Station station);
  Future<void> deleteStation(int id);
  Future<void> saveBuilding(Building building);
  Future<void> deleteBuilding(int id);
  Future<void> deleteAllStations();
  Future<void> addStation(Station station);

  // Cards
  Future<List<BankAlHazCard>> getCards();
  Future<int> saveCard(BankAlHazCard card);
  Future<void> addCard(BankAlHazCard card);
  Future<void> deleteCard(int id);
  Future<void> deleteAllCards();

  // Settings
  Future<BankAlHazSettings> getSettings();
  Future<void> saveSettings(BankAlHazSettings settings);
}
