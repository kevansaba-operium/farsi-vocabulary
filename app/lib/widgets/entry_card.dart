import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/vocab_entry.dart';
import '../providers/srs_provider.dart';
import 'phonetic_text.dart';

class EntryCard extends ConsumerWidget {
  final VocabEntry entry;
  final bool showFavorite;

  const EntryCard({super.key, required this.entry, this.showFavorite = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = ref.watch(srsProvider)[entry.id];
    final isFav = cs?.isFavorite ?? false;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/entry/${entry.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (entry.farsi.isNotEmpty)
                      PhoneticText(
                        entry.farsi,
                        isFarsi: true,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 4),
                    // Transliteration
                    if (entry.transliteration.isNotEmpty)
                      PhoneticText(
                        entry.transliteration,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 2),
                    // English
                    Text(
                      entry.english,
                      style: TextStyle(
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (entry.partOfSpeech != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          entry.partOfSpeech!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showFavorite)
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () =>
                      ref.read(srsProvider.notifier).toggleFavorite(entry.id),
                  tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
