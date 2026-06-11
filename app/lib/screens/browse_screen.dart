import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/lesson.dart';
import '../providers/vocabulary_provider.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Lessons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Search',
          ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final lessons = data.lessons;
          if (lessons.isEmpty) {
            return const Center(child: Text('No lessons loaded.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final count = lesson.entryIds.length;
              return _LessonTile(lesson: lesson, entryCount: count);
            },
          );
        },
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;
  final int entryCount;

  const _LessonTile({required this.lesson, required this.entryCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLesson = lesson.isLesson;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLesson
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          child: Icon(
            isLesson ? Icons.class_ : Icons.note_alt_outlined,
            color: isLesson
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        title: Text(lesson.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${lesson.date ?? ''} · $entryCount words',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.style_outlined),
              onPressed: () => context.push('/flashcards?lesson=${lesson.id}'),
              tooltip: 'Flashcards',
            ),
            IconButton(
              icon: const Icon(Icons.quiz_outlined),
              onPressed: () => context.push('/quiz?lesson=${lesson.id}'),
              tooltip: 'Quiz',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push(
          '/browse/lesson/${lesson.id}?label=${Uri.encodeComponent(lesson.label)}',
        ),
      ),
    );
  }
}
