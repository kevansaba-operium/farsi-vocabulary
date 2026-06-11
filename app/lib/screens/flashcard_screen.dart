import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vocab_entry.dart';
import '../providers/vocabulary_provider.dart';
import '../providers/srs_provider.dart';
import '../widgets/phonetic_text.dart';
import '../widgets/edit_entry_sheet.dart';

class FlashcardScreen extends ConsumerStatefulWidget {
  final String? lessonId;
  const FlashcardScreen({super.key, this.lessonId});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late List<VocabEntry> _deck;
  int _index = 0;
  bool _showBack = false;
  bool _ready = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _buildDeck(VocabularyData data) {
    List<VocabEntry> entries;
    if (widget.lessonId != null) {
      entries = data.entriesForLesson(widget.lessonId!);
    } else {
      entries = List.from(data.entries);
    }
    entries = entries.where((e) => e.farsi.isNotEmpty).toList();
    entries.shuffle(Random());
    _deck = entries;
    _ready = true;
  }

  void _flip() {
    if (_showBack) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _next() {
    _flipCtrl.reset();
    setState(() {
      _showBack = false;
      _index = (_index + 1) % _deck.length;
    });
  }

  void _prev() {
    _flipCtrl.reset();
    setState(() {
      _showBack = false;
      _index = (_index - 1 + _deck.length) % _deck.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vocabAsync = ref.watch(vocabularyProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonId != null ? 'Flashcards' : 'All Cards'),
        actions: [
          if (_ready && _deck.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_index + 1} / ${_deck.length}'),
              ),
            ),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (!_ready) _buildDeck(data);
          if (_deck.isEmpty) {
            return const Center(child: Text('No cards available for this lesson.'));
          }
          final entry = _deck[_index];
          return Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _flip,
                  child: AnimatedBuilder(
                    animation: _flipAnim,
                    builder: (context, child) {
                      final angle = _flipAnim.value * pi;
                      final showFront = angle < pi / 2;
                      return Transform(
                        transform: Matrix4.rotationY(angle),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: showFront
                              ? _CardFace(
                                  entry: entry,
                                  isFront: true,
                                  key: ValueKey('front-${entry.id}'),
                                )
                              : Transform(
                                  transform: Matrix4.rotationY(pi),
                                  alignment: Alignment.center,
                                  child: _CardFace(
                                    entry: entry,
                                    isFront: false,
                                    key: ValueKey('back-${entry.id}'),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Navigation & rating row
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      if (_showBack) _RatingRow(entryId: entry.id, onNext: _next),
                      if (!_showBack)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _prev,
                              icon: const Icon(Icons.arrow_back_ios),
                              tooltip: 'Previous',
                            ),
                            OutlinedButton(
                              onPressed: _flip,
                              child: const Text('Show answer'),
                            ),
                            IconButton(
                              onPressed: _next,
                              icon: const Icon(Icons.arrow_forward_ios),
                              tooltip: 'Skip',
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap card to flip',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardFace extends ConsumerWidget {
  final VocabEntry entry;
  final bool isFront;

  const _CardFace({required this.entry, required this.isFront, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 6,
      color: isFront ? colorScheme.primaryContainer : colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox.expand(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: isFront
                    ? [
                    // Front: Farsi + transliteration
                    if (entry.farsi.isNotEmpty)
                      PhoneticText(
                        entry.farsi,
                        isFarsi: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    const SizedBox(height: 12),
                    PhoneticText(
                      entry.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'What does this mean?',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.6),
                      ),
                    ),
                  ]
                : [
                    // Back: English + notes
                    Text(
                      entry.english,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                    if (entry.partOfSpeech != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        entry.partOfSpeech!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (entry.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        entry.notes,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: colorScheme.onSecondaryContainer.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ],
              ),
            ),
            // Edit icon on back face only
            if (!isFront)
              Positioned(
                top: 8,
                right: 8,
                child: EditEntryButton(entryId: entry.id, entry: entry),
              ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends ConsumerWidget {
  final String entryId;
  final VoidCallback onNext;

  const _RatingRow({required this.entryId, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn(context, ref, 1, "Again", Colors.red),
          _btn(context, ref, 3, "Hard", Colors.orange),
          _btn(context, ref, 4, "Good", Colors.green),
          _btn(context, ref, 5, "Easy", Colors.blue),
        ],
      ),
    );
  }

  Widget _btn(BuildContext ctx, WidgetRef ref, int q, String label, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () {
            ref.read(srsProvider.notifier).recordReview(entryId, q);
            onNext();
          },
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
