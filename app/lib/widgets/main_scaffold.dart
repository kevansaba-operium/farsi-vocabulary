import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/browse')) return 1;
    if (location.startsWith('/srs')) return 2;
    if (location.startsWith('/search')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    // Each tab screen owns its own Scaffold. Avoid nesting Scaffolds here —
    // that can collapse the body to zero height on some Android release builds.
    return Column(
      children: [
        Expanded(child: child),
        NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/');
              case 1:
                context.go('/browse');
              case 2:
                context.go('/srs');
              case 3:
                context.go('/search');
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Browse'),
            NavigationDestination(icon: Icon(Icons.repeat_outlined), selectedIcon: Icon(Icons.repeat), label: 'Review'),
            NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          ],
        ),
      ],
    );
  }
}
