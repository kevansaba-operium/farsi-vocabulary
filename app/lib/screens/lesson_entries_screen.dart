import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/vocabulary_provider.dart';
import '../widgets/entry_card.dart';

class LessonEntriesScreen extends ConsumerWidget {
  final String lessonId;
  final String label;

  const LessonEntriesScreen({
    super.key,
    required this.lessonId,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(label.isNotEmpty ? label : lessonId),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'flashcards') {
                context.push('/flashcards?lesson=$lessonId');
              } else if (val == 'quiz') {
                context.push('/quiz?lesson=$lessonId');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'flashcards', child: Text('Flashcards')),
              const PopupMenuItem(value: 'quiz', child: Text('Quiz')),
            ],
          ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final entries = data.entriesForLesson(lessonId);
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No entries for this lesson yet.\nComplete the vision extraction step to add vocabulary.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${entries.length} words',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, i) => EntryCard(entry: entries[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
