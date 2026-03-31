import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/bank_al_haz_repository_impl.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../../domain/repositories/bank_al_haz_repository.dart';

final bankAlHazRepositoryProvider = Provider<BankAlHazRepository>((ref) {
  return BankAlHazRepositoryImpl();
});

final templatesProvider = FutureProvider<List<BankAlHazTemplate>>((ref) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  return repository.getTemplates();
});

final stationsProvider = FutureProvider<List<Station>>((ref) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  final settings = await ref.watch(gameSettingsProvider.future);
  return repository.getStations(templateId: settings.activeTemplateId);
});

final savedGameExistsProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(bankAlHazRepositoryProvider);
  final state = await repo.getGameState();
  return state != null;
});

final cardsProvider = FutureProvider<List<BankAlHazCard>>((ref) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  final settings = await ref.watch(gameSettingsProvider.future);
  return repository.getCards(templateId: settings.activeTemplateId);
});

final stationsByTemplateProvider = FutureProvider.family<List<Station>, int>((ref, templateId) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  return repository.getStations(templateId: templateId);
});

final cardsByTemplateProvider = FutureProvider.family<List<BankAlHazCard>, int>((ref, templateId) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  return repository.getCards(templateId: templateId);
});

final gameSettingsProvider = FutureProvider<BankAlHazSettings>((ref) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  return repository.getSettings();
});

