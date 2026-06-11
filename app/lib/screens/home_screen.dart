import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/vocabulary_provider.dart';
import '../providers/srs_provider.dart';
import '../models/vocab_entry.dart';
import '../widgets/phonetic_text.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyProvider);
    final wotdAsync = ref.watch(wordOfTheDayProvider);
    final dueCount = ref.watch(dueCountProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final dateStr = '${_month(today.month)} ${today.day}, ${today.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farsi Vocabulary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading vocabulary: $e')),
        data: (data) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word of the day
                _WordOfTheDayCard(wotdAsync: wotdAsync, dateStr: dateStr),
                // Stats row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        icon: Icons.library_books_outlined,
                        label: '${data.entries.length} words',
                        color: colorScheme.secondaryContainer,
                      ),
                      _StatChip(
                        icon: Icons.class_outlined,
                        label: '${data.lessons.length} lessons',
                        color: colorScheme.tertiaryContainer,
                      ),
                      if (dueCount > 0)
                        _StatChip(
                          icon: Icons.notification_important_outlined,
                          label: '$dueCount due',
                          color: Colors.orange.shade100,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Study modes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Study',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                _StudyGrid(),
                const SizedBox(height: 16),
                // Due review banner
                if (dueCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _DueBanner(dueCount: dueCount),
                  ),
                const SizedBox(height: 16),
                // Recent lessons quick-access
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Recent lessons',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                _RecentLessons(data: data),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _month(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ---------------------------------------------------------------------------

class _WordOfTheDayCard extends StatelessWidget {
  final AsyncValue<VocabEntry?> wotdAsync;
  final String dateStr;

  const _WordOfTheDayCard({required this.wotdAsync, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final entry = wotdAsync.value;
            if (entry != null) context.push('/entry/${entry.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined,
                        size: 16, color: colorScheme.onPrimaryContainer.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Word of the day · $dateStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                wotdAsync.when(
                  loading: () => const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text('Error: $e'),
                  data: (entry) {
                    if (entry == null) {
                      return const Text('No vocabulary loaded yet.');
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PhoneticText(
                          entry.farsi,
                          isFarsi: true,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (entry.transliteration.isNotEmpty)
                          PhoneticText(
                            entry.transliteration,
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          entry.english,
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (entry.partOfSpeech != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              entry.partOfSpeech!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StudyGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StudyCard(
              icon: Icons.style_outlined,
              title: 'Flashcards',
              subtitle: 'Flip through all cards',
              color: Colors.indigo,
              onTap: () => context.push('/flashcards'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StudyCard(
              icon: Icons.quiz_outlined,
              title: 'Quiz',
              subtitle: 'Multiple choice',
              color: Colors.teal,
              onTap: () => context.push('/quiz'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StudyCard(
              icon: Icons.repeat_outlined,
              title: 'Review',
              subtitle: 'Spaced repetition',
              color: Colors.deepOrange,
              onTap: () => context.push('/srs'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _StudyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  final int dueCount;
  const _DueBanner({required this.dueCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/srs'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.notification_important, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dueCount card${dueCount != 1 ? 's' : ''} due for review',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Tap to start your SRS session now',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentLessons extends StatelessWidget {
  final VocabularyData data;
  const _RecentLessons({required this.data});

  @override
  Widget build(BuildContext context) {
    final recent = data.lessons.reversed.take(5).toList();
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: recent.length,
        itemBuilder: (context, i) {
          final lesson = recent[i];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(
                '/browse/lesson/${lesson.id}?label=${Uri.encodeComponent(lesson.label)}',
              ),
              child: Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lesson.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lesson.date != null)
                      Text(
                        lesson.date!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      '${lesson.entryIds.length} words',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
