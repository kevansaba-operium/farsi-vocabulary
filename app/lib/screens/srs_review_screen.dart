import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocab_entry.dart';
import '../providers/vocabulary_provider.dart';
import '../providers/srs_provider.dart';
import '../widgets/phonetic_text.dart';
import '../widgets/edit_entry_sheet.dart';

class SrsReviewScreen extends ConsumerStatefulWidget {
  const SrsReviewScreen({super.key});

  @override
  ConsumerState<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends ConsumerState<SrsReviewScreen> {
  List<VocabEntry>? _queue;
  int _index = 0;
  bool _revealed = false;
  int _sessionReviewed = 0;

  List<VocabEntry> _buildQueue(VocabularyData data) {
    final srs = ref.read(srsProvider);
    // Due cards (studied before) first, then new (never reviewed)
    final dueIds = srs.values.where((cs) => cs.isDue && cs.hasBeenStudied).map((cs) => cs.entryId).toSet();
    final due = data.entries.where((e) => dueIds.contains(e.id) && e.farsi.isNotEmpty).toList();
    // Add new cards (up to 20) at the end
    final studiedIds = srs.keys.toSet();
    final newCards = data.entries
        .where((e) => !studiedIds.contains(e.id) && e.farsi.isNotEmpty)
        .take(20)
        .toList();
    return [...due, ...newCards];
  }

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(vocabularyProvider);
    // Watch srs to rebuild when state changes
    ref.watch(srsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SRS Review'),
        actions: [
          if (_queue != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('$_sessionReviewed reviewed'),
              ),
            ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          _queue ??= _buildQueue(data);
          final queue = _queue!;

          if (queue.isEmpty || _index >= queue.length) {
            return _FinishedView(
              sessionReviewed: _sessionReviewed,
              onRestart: () => setState(() {
                _queue = null;
                _index = 0;
                _revealed = false;
                _sessionReviewed = 0;
              }),
            );
          }

          final entry = queue[_index];
          return _ReviewCard(
            entry: entry,
            revealed: _revealed,
            onReveal: () => setState(() => _revealed = true),
            onRate: (quality) {
              ref.read(srsProvider.notifier).recordReview(entry.id, quality);
              setState(() {
                _index++;
                _revealed = false;
                _sessionReviewed++;
              });
            },
            queueLength: queue.length,
            currentIndex: _index,
          );
        },
      ),
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final VocabEntry entry;
  final bool revealed;
  final VoidCallback onReveal;
  final void Function(int quality) onRate;
  final int queueLength;
  final int currentIndex;

  const _ReviewCard({
    required this.entry,
    required this.revealed,
    required this.onReveal,
    required this.onRate,
    required this.queueLength,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Progress
        LinearProgressIndicator(value: currentIndex / queueLength),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${currentIndex + 1} / $queueLength',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('${queueLength - currentIndex} remaining',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Prompt side – Farsi
                      if (entry.farsi.isNotEmpty)
                        PhoneticText(
                          entry.farsi,
                          isFarsi: true,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 8),
                      PhoneticText(
                        entry.transliteration,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Divider(height: 28),
                      if (!revealed)
                        TextButton(
                          onPressed: onReveal,
                          child: const Text('Show meaning →'),
                        )
                      else ...[
                        Text(
                          entry.english,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (entry.partOfSpeech != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              entry.partOfSpeech!,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ),
                        if (entry.notes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entry.notes,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Rating buttons
        if (revealed)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('How well did you know it?'),
                      const SizedBox(width: 8),
                      EditEntryButton(entryId: entry.id, entry: entry, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _rateBtn(context, 1, 'Again', Colors.red),
                      _rateBtn(context, 3, 'Hard', Colors.orange),
                      _rateBtn(context, 4, 'Good', Colors.green),
                      _rateBtn(context, 5, 'Easy', Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _rateBtn(BuildContext ctx, int q, String label, Color color) {
    // ignore: avoid_unused_parameters
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
          onPressed: () => onRate(q),
          child: Text(label),
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  final int sessionReviewed;
  final VoidCallback onRestart;

  const _FinishedView({required this.sessionReviewed, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              sessionReviewed > 0
                  ? 'Session complete!\nYou reviewed $sessionReviewed cards.'
                  : 'Nothing due right now.\nCome back later!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh),
              label: const Text('Start new session'),
            ),
          ],
        ),
      ),
    );
  }
}
