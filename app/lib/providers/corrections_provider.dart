import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/correction.dart';
import '../models/vocab_entry.dart';
import 'vocabulary_provider.dart';

const _boxName = 'corrections';

class CorrectionsNotifier extends Notifier<Map<String, Correction>> {
  late Box<String> _box;

  @override
  Map<String, Correction> build() {
    _box = Hive.box<String>(_boxName);
    return _loadAll();
  }

  Map<String, Correction> _loadAll() {
    final result = <String, Correction>{};
    for (final key in _box.keys) {
      final raw = _box.get(key as String);
      if (raw != null) {
        try {
          result[key] = Correction.fromJsonString(raw);
        } catch (_) {
          // ignore corrupt entries
        }
      }
    }
    return result;
  }

  /// Save a correction (overrides any previous correction for this entry).
  Future<void> save(Correction correction) async {
    await _box.put(correction.entryId, correction.toJsonString());
    state = {...state, correction.entryId: correction};
  }

  /// Clear a correction, reverting the entry to its original data.
  Future<void> clear(String entryId) async {
    await _box.delete(entryId);
    final updated = Map<String, Correction>.from(state);
    updated.remove(entryId);
    state = updated;
  }
}

final correctionsProvider =
    NotifierProvider<CorrectionsNotifier, Map<String, Correction>>(
  CorrectionsNotifier.new,
);

/// Returns the effective [VocabEntry] for [entryId], merging any user
/// correction on top of the base data.
final effectiveEntryProvider =
    Provider.family<VocabEntry?, String>((ref, entryId) {
  final vocabAsync = ref.watch(vocabularyProvider);
  final corrections = ref.watch(correctionsProvider);

  return vocabAsync.whenOrNull(data: (data) {
    final base = data.entries.cast<VocabEntry?>().firstWhere(
          (e) => e?.id == entryId,
          orElse: () => null,
        );
    if (base == null) return null;

    final correction = corrections[entryId];
    if (correction == null) return base;

    return VocabEntry(
      id: base.id,
      farsi: correction.farsi ?? base.farsi,
      transliteration: correction.transliteration ?? base.transliteration,
      english: correction.english ?? base.english,
      partOfSpeech: correction.partOfSpeech ?? base.partOfSpeech,
      notes: correction.notes ?? base.notes,
      examples: base.examples,
      imagePath: base.imagePath,
      tags: base.tags,
      sourceFile: base.sourceFile,
      lessonNumber: base.lessonNumber,
      date: base.date,
      needsReview: base.needsReview,
    );
  });
});
