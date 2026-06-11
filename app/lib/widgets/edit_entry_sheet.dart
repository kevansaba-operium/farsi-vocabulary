import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/correction.dart';
import '../models/vocab_entry.dart';
import '../providers/corrections_provider.dart';

/// Small edit icon button that opens [EditEntrySheet].
/// Place this in any card or AppBar action.
class EditEntryButton extends StatelessWidget {
  final String entryId;
  final VocabEntry entry;
  final double size;

  const EditEntryButton({
    super.key,
    required this.entryId,
    required this.entry,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: size,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        Icons.edit_outlined,
        size: size,
        color: IconTheme.of(context).color?.withOpacity(0.6),
      ),
      tooltip: 'Edit / correct entry',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditEntrySheet(entryId: entryId, entry: entry),
      ),
    );
  }
}

/// Modal bottom sheet with text fields for correcting a vocabulary entry.
class EditEntrySheet extends ConsumerStatefulWidget {
  final String entryId;
  final VocabEntry entry;

  const EditEntrySheet({
    super.key,
    required this.entryId,
    required this.entry,
  });

  @override
  ConsumerState<EditEntrySheet> createState() => _EditEntrySheetState();
}

class _EditEntrySheetState extends ConsumerState<EditEntrySheet> {
  late final TextEditingController _farsiCtrl;
  late final TextEditingController _translitCtrl;
  late final TextEditingController _englishCtrl;
  late final TextEditingController _posCtrl;
  late final TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final corrections = ref.read(correctionsProvider);
    final existing = corrections[widget.entryId];
    _farsiCtrl =
        TextEditingController(text: existing?.farsi ?? widget.entry.farsi);
    _translitCtrl = TextEditingController(
        text: existing?.transliteration ?? widget.entry.transliteration);
    _englishCtrl = TextEditingController(
        text: existing?.english ?? widget.entry.english);
    _posCtrl = TextEditingController(
        text: existing?.partOfSpeech ?? widget.entry.partOfSpeech ?? '');
    _notesCtrl =
        TextEditingController(text: existing?.notes ?? widget.entry.notes);
  }

  @override
  void dispose() {
    _farsiCtrl.dispose();
    _translitCtrl.dispose();
    _englishCtrl.dispose();
    _posCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final correction = Correction(
      entryId: widget.entryId,
      farsi: _farsiCtrl.text.trim().isEmpty ? null : _farsiCtrl.text.trim(),
      transliteration: _translitCtrl.text.trim().isEmpty
          ? null
          : _translitCtrl.text.trim(),
      english:
          _englishCtrl.text.trim().isEmpty ? null : _englishCtrl.text.trim(),
      partOfSpeech:
          _posCtrl.text.trim().isEmpty ? null : _posCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await ref.read(correctionsProvider.notifier).save(correction);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correction saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearCorrections() async {
    await ref.read(correctionsProvider.notifier).clear(widget.entryId);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrections cleared – original restored'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final corrections = ref.watch(correctionsProvider);
    final hasExisting = corrections.containsKey(widget.entryId);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                'Correct entry',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (hasExisting)
                TextButton(
                  onPressed: _clearCorrections,
                  child: const Text('Clear corrections'),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close',
              ),
            ],
          ),
          const Divider(height: 8),
          const SizedBox(height: 8),
          TextField(
            controller: _farsiCtrl,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'Farsi (فارسی)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _translitCtrl,
            decoration: const InputDecoration(
              labelText: 'Transliteration (Penglish)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _englishCtrl,
            decoration: const InputDecoration(
              labelText: 'English meaning',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _posCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Part of speech',
                    border: OutlineInputBorder(),
                    isDense: true,
                    hintText: 'noun / verb / adj…',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save correction'),
          ),
        ],
      ),
    );
  }
}
