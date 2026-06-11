import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/browse_screen.dart';
import '../screens/lesson_entries_screen.dart';
import '../screens/entry_detail_screen.dart';
import '../screens/flashcard_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/srs_review_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/main_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/browse',
          builder: (context, state) => const BrowseScreen(),
          routes: [
            GoRoute(
              path: 'lesson/:lessonId',
              builder: (context, state) {
                final lessonId = state.pathParameters['lessonId']!;
                final label = state.uri.queryParameters['label'] ?? '';
                return LessonEntriesScreen(lessonId: lessonId, label: label);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/entry/:entryId',
          builder: (context, state) {
            return EntryDetailScreen(entryId: state.pathParameters['entryId']!);
          },
        ),
        GoRoute(
          path: '/flashcards',
          builder: (context, state) {
            final lessonId = state.uri.queryParameters['lesson'];
            return FlashcardScreen(lessonId: lessonId);
          },
        ),
        GoRoute(
          path: '/quiz',
          builder: (context, state) {
            final lessonId = state.uri.queryParameters['lesson'];
            return QuizScreen(lessonId: lessonId);
          },
        ),
        GoRoute(
          path: '/srs',
          builder: (context, state) => const SrsReviewScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
