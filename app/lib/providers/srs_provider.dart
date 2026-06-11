import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/card_state.dart';

const _boxName = 'card_states';

/// Provides access to the Hive box for card SRS state.
final cardStateBoxProvider = Provider<Box<CardState>>((ref) {
  return Hive.box<CardState>(_boxName);
});

/// Notifier that wraps Hive for SRS card state.
class SrsNotifier extends Notifier<Map<String, CardState>> {
  @override
  Map<String, CardState> build() {
    try {
      final box = ref.watch(cardStateBoxProvider);
      return Map.fromEntries(
        box.toMap().entries.cast<MapEntry<String, CardState>>(),
      );
    } catch (_) {
      return {};
    }
  }

  Box<CardState> get _box => ref.read(cardStateBoxProvider);

  CardState getOrCreate(String entryId) {
    return _box.get(entryId) ?? CardState(entryId: entryId);
  }

  Future<void> recordReview(String entryId, int quality) async {
    final cs = getOrCreate(entryId);
    cs.recordReview(quality);
    await _box.put(entryId, cs);
    state = Map.from(state)..[entryId] = cs;
  }

  Future<void> toggleFavorite(String entryId) async {
    final cs = getOrCreate(entryId);
    cs.isFavorite = !cs.isFavorite;
    await _box.put(entryId, cs);
    state = Map.from(state)..[entryId] = cs;
  }

  List<String> dueEntryIds() {
    return _box.values.where((cs) => cs.isDue).map((cs) => cs.entryId).toList();
  }

  List<String> favoriteEntryIds() {
    return _box.values
        .where((cs) => cs.isFavorite)
        .map((cs) => cs.entryId)
        .toList();
  }

  int get dueCount => _box.values.where((cs) => cs.isDue && cs.hasBeenStudied).length;
}

final srsProvider = NotifierProvider<SrsNotifier, Map<String, CardState>>(
  SrsNotifier.new,
);

final dueCountProvider = Provider<int>((ref) {
  try {
    ref.watch(srsProvider);
    final box = ref.read(cardStateBoxProvider);
    return box.values.where((cs) => cs.isDue && cs.hasBeenStudied).length;
  } catch (_) {
    return 0;
  }
});
