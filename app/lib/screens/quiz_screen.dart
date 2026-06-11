import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocab_entry.dart';
import '../providers/vocabulary_provider.dart';
import '../providers/srs_provider.dart';
import '../widgets/phonetic_text.dart';
import '../widgets/edit_entry_sheet.dart';

enum QuizDirection { farsiToEnglish, englishToFarsi }

class QuizScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  const QuizScreen({super.key, this.lessonId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late List<_QuizQuestion> _questions;
  int _index = 0;
  int? _selectedOption;
  bool _answered = false;
  int _correct = 0;
  bool _ready = false;
  final QuizDirection _direction = QuizDirection.farsiToEnglish;

  static const int _questionsPerSession = 10;
  static const int _optionsCount = 4;

  void _buildQuiz(VocabularyData data) {
    List<VocabEntry> pool;
    if (widget.lessonId != null) {
      pool = data.entriesForLesson(widget.lessonId!);
    } else {
      pool = List.from(data.entries);
    }
    pool = pool.where((e) => e.farsi.isNotEmpty && e.english.isNotEmpty).toList();
    pool.shuffle(Random());

    final allEntries = data.entries
        .where((e) => e.farsi.isNotEmpty && e.english.isNotEmpty)
        .toList();

    _questions = pool.take(_questionsPerSession).map((entry) {
      // Build 3 distractors from the full pool
      final distractors = (List.from(allEntries)..remove(entry)..shuffle())
          .take(_optionsCount - 1)
          .cast<VocabEntry>()
          .toList();
      final options = [entry, ...distractors]..shuffle(Random());
      return _QuizQuestion(
        entry: entry,
        options: options,
        correctIndex: options.indexOf(entry),
      );
    }).toList();

    _ready = true;
  }

  void _select(int idx) {
    if (_answered) return;
    final q = _questions[_index];
    final isCorrect = idx == q.correctIndex;
    if (isCorrect) _correct++;
    setState(() {
      _selectedOption = idx;
      _answered = true;
    });
    // Record SRS
    ref.read(srsProvider.notifier).recordReview(
      q.entry.id,
      isCorrect ? 4 : 1,
    );
  }

  void _next() {
    setState(() {
      _index++;
      _selectedOption = null;
      _answered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(vocabularyProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonId != null ? 'Quiz' : 'All-deck Quiz'),
        actions: [
          if (_ready && _index < _questions.length)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_index + 1}/${_questions.length}'),
              ),
            ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (!_ready) _buildQuiz(data);
          if (_questions.isEmpty) {
            return const Center(
                child: Text('Not enough entries for a quiz.\nAdd more vocabulary first.'));
          }
          if (_index >= _questions.length) {
            return _ResultScreen(
              correct: _correct,
              total: _questions.length,
              onRetry: () => setState(() {
                _ready = false;
                _index = 0;
                _correct = 0;
                _answered = false;
                _selectedOption = null;
              }),
            );
          }
          final q = _questions[_index];
          return _QuizView(
            question: q,
            direction: _direction,
            selectedOption: _selectedOption,
            answered: _answered,
            onSelect: _select,
            onNext: _next,
          );
        },
      ),
    );
  }
}

class _QuizQuestion {
  final VocabEntry entry;
  final List<VocabEntry> options;
  final int correctIndex;

  _QuizQuestion({
    required this.entry,
    required this.options,
    required this.correctIndex,
  });
}

class _QuizView extends StatelessWidget {
  final _QuizQuestion question;
  final QuizDirection direction;
  final int? selectedOption;
  final bool answered;
  final void Function(int) onSelect;
  final VoidCallback onNext;

  const _QuizView({
    required this.question,
    required this.direction,
    required this.selectedOption,
    required this.answered,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entry = question.entry;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question card
            Card(
              color: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'What does this mean?',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    PhoneticText(
                      entry.farsi,
                      isFarsi: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PhoneticText(
                      entry.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Options
            ...question.options.asMap().entries.map((e) {
              final idx = e.key;
              final option = e.value;
              final isCorrect = idx == question.correctIndex;
              final isSelected = idx == selectedOption;

              Color? bg;
              if (answered) {
                if (isCorrect) bg = Colors.green.shade100;
                if (isSelected && !isCorrect) bg = Colors.red.shade100;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: answered ? null : () => onSelect(idx),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: bg ?? colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: answered && isCorrect
                            ? Colors.green
                            : answered && isSelected
                                ? Colors.red
                                : colorScheme.outline,
                        width: answered && (isCorrect || isSelected) ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option.english,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: answered && isCorrect
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (answered && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (answered && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            if (answered)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onNext,
                      child: const Text('Next →'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  EditEntryButton(
                    entryId: entry.id,
                    entry: entry,
                    size: 20,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onRetry;

  const _ResultScreen({required this.correct, required this.total, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final pct = (correct / total * 100).round();
    final Color color = pct >= 80 ? Colors.green : pct >= 50 ? Colors.orange : Colors.red;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pct >= 80 ? Icons.emoji_events : Icons.school,
              size: 72,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              'Quiz Complete!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '$correct / $total correct  ($pct%)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
