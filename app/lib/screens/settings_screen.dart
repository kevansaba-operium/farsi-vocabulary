import 'package:flutter/material.dart';
import '../widgets/phonetic_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader('Text direction'),
          const ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('Farsi script → right to left'),
            subtitle: Text('Persian characters are always shown RTL.'),
          ),
          const ListTile(
            leading: Icon(Icons.abc),
            title: Text('Transliteration → left to right'),
            subtitle: Text('Latin spellings (Penglish) are always shown LTR.'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview:',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 6),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PhoneticText(
                          'خوش آمدید',
                          isFarsi: true,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        PhoneticText(
                          'khosh āmadid',
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                        SizedBox(height: 4),
                        Text('welcome'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Farsi Vocabulary'),
            subtitle: Text('Offline vocabulary learner · v1.0'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
