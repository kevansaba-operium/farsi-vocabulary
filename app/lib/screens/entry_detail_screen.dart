import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocab_entry.dart';
import '../providers/vocabulary_provider.dart';
import '../providers/srs_provider.dart';
import '../providers/corrections_provider.dart';
import '../widgets/phonetic_text.dart';
import '../widgets/edit_entry_sheet.dart';

class EntryDetailScreen extends ConsumerWidget {
  final String entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return vocabAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (data) {
        final baseEntry = data.entriesById[entryId];
        if (baseEntry == null) {
          return const Scaffold(body: Center(child: Text('Entry not found.')));
        }
        final entry = ref.watch(effectiveEntryProvider(entryId)) ?? baseEntry;
        final cs = ref.watch(srsProvider)[entryId];
        final isFav = cs?.isFavorite ?? false;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Entry'),
            actions: [
              EditEntryButton(entryId: entryId, entry: entry),
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null),
                onPressed: () =>
                    ref.read(srsProvider.notifier).toggleFavorite(entryId),
                tooltip: 'Favorite',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farsi card
                _FarsiCard(entry: entry),
                const SizedBox(height: 20),
                // Details
                if (entry.partOfSpeech != null) ...[
                  const _Label('Part of speech'),
                  Text(entry.partOfSpeech!, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                ],
                if (entry.notes.isNotEmpty) ...[
                  const _Label('Notes'),
                  Text(entry.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 14),
                ],
                if (entry.examples.isNotEmpty) ...[
                  const _Label('Examples'),
                  ...entry.examples.map((ex) => _ExampleTile(ex: ex)),
                  const SizedBox(height: 14),
                ],
                // Phonetic legend
                const SizedBox(height: 8),
                const ExpansionTile(
                  title: Text('Phonetic guide', style: TextStyle(fontSize: 13)),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: PhoneticLegend(),
                    ),
                  ],
                ),
                // SRS info
                if (cs != null && cs.hasBeenStudied) ...[
                  const SizedBox(height: 8),
                  const _Label('Study progress'),
                  Text('Reviews: ${cs.totalReviews}  ·  '
                      'Interval: ${cs.intervalDays}d  ·  '
                      'Next: ${cs.nextDue?.toLocal().toString().split(' ').first ?? '—'}'),
                ],
                const SizedBox(height: 32),
                // Quick review buttons
                _QuickReviewRow(entryId: entryId),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FarsiCard extends StatelessWidget {
  final VocabEntry entry;
  const _FarsiCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry.farsi.isNotEmpty)
              PhoneticText(
                entry.farsi,
                isFarsi: true,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            if (entry.transliteration.isNotEmpty) ...[
              const SizedBox(height: 8),
              PhoneticText(
                entry.transliteration,
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              entry.english,
              style: TextStyle(
                fontSize: 22,
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExampleTile extends StatelessWidget {
  final VocabExample ex;
  const _ExampleTile({required this.ex});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ex.farsi.isNotEmpty)
              PhoneticText(
                ex.farsi,
                isFarsi: true,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
            if (ex.transliteration.isNotEmpty) ...[
              const SizedBox(height: 4),
              PhoneticText(
                ex.transliteration,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (ex.english.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(ex.english, style: const TextStyle(fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickReviewRow extends ConsumerWidget {
  final String entryId;
  const _QuickReviewRow({required this.entryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mark how well you knew this:',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ReviewButton(entryId: entryId, quality: 1, label: "Didn't know", color: Colors.red),
            _ReviewButton(entryId: entryId, quality: 3, label: 'Hard', color: Colors.orange),
            _ReviewButton(entryId: entryId, quality: 4, label: 'Good', color: Colors.green),
            _ReviewButton(entryId: entryId, quality: 5, label: 'Easy', color: Colors.blue),
          ],
        ),
      ],
    );
  }
}

class _ReviewButton extends ConsumerWidget {
  final String entryId;
  final int quality;
  final String label;
  final Color color;

  const _ReviewButton({
    required this.entryId,
    required this.quality,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: () {
        ref.read(srsProvider.notifier).recordReview(entryId, quality);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recorded: $label'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
