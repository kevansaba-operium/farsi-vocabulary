import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocab_entry.dart';
import '../models/lesson.dart';

/// Loaded vocabulary dataset from the bundled asset.
class VocabularyData {
  final List<VocabEntry> entries;
  final List<Lesson> lessons;
  final Map<String, VocabEntry> entriesById;

  VocabularyData({
    required this.entries,
    required this.lessons,
  }) : entriesById = {for (final e in entries) e.id: e};

  List<VocabEntry> entriesForLesson(String lessonId) {
    final lesson = lessons.firstWhere(
      (l) => l.id == lessonId,
      orElse: () => const Lesson(id: '', label: ''),
    );
    return lesson.entryIds
        .map((id) => entriesById[id])
        .whereType<VocabEntry>()
        .toList();
  }

  List<VocabEntry> search(String query) {
    if (query.trim().isEmpty) return entries;
    final q = query.toLowerCase().trim();
    return entries.where((e) {
      return e.english.toLowerCase().contains(q) ||
          e.transliteration.toLowerCase().contains(q) ||
          e.farsi.contains(q) ||
          (e.notes.toLowerCase().contains(q));
    }).toList();
  }
}

final vocabularyProvider = FutureProvider<VocabularyData>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/data/vocabulary.json');
  final raw = jsonDecode(jsonStr) as Map<String, dynamic>;

  final entries = (raw['entries'] as List<dynamic>)
      .map((e) => VocabEntry.fromJson(e as Map<String, dynamic>))
      .where((e) => !e.isEmpty)
      .toList();

  final lessons = (raw['lessons'] as List<dynamic>)
      .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
      .toList();

  return VocabularyData(entries: entries, lessons: lessons);
});

/// Word of the day: deterministic pick based on today's date
final wordOfTheDayProvider = Provider<AsyncValue<VocabEntry?>>((ref) {
  return ref.watch(vocabularyProvider).whenData((data) {
    if (data.entries.isEmpty) return null;
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final usable = data.entries.where((e) => e.farsi.isNotEmpty).toList();
    if (usable.isEmpty) return null;
    return usable[seed % usable.length];
  });
});
