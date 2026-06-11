import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/vocab_entry.dart';
import 'models/card_state.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(VocabEntryAdapter());
  Hive.registerAdapter(VocabExampleAdapter());
  Hive.registerAdapter(CardStateAdapter());
  await _openBox<CardState>('card_states');
  await _openBox<String>('corrections');

  runApp(const ProviderScope(child: FarsiVocabularyApp()));
}

Future<Box<T>> _openBox<T>(String name) async {
  try {
    return await Hive.openBox<T>(name);
  } catch (_) {
    await Hive.deleteBoxFromDisk(name);
    return Hive.openBox<T>(name);
  }
}

class FarsiVocabularyApp extends StatelessWidget {
  const FarsiVocabularyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Farsi Vocabulary',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: appRouter,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seed = Color(0xFF1B5E20); // deep green – inspired by Persian art
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'sans-serif',
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
