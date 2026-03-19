import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/bank_al_haz_repository_impl.dart';
import '../../domain/entities/bank_al_haz_entities.dart';
import '../../domain/repositories/bank_al_haz_repository.dart';

final bankAlHazRepositoryProvider = Provider<BankAlHazRepository>((ref) {
  return BankAlHazRepositoryImpl();
});

final stationsProvider = FutureProvider<List<Station>>((ref) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  return repository.getStations();
});

final cardsProvider = FutureProvider<List<BankAlHazCard>>((ref) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  return repository.getCards();
});

final gameSettingsProvider = FutureProvider<BankAlHazSettings>((ref) async {
  final repository = ref.watch(bankAlHazRepositoryProvider);
  return repository.getSettings();
});
