import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/widgets/bottom_nav_bar.dart';

/// Shell that wraps the main screens with a persistent bottom nav bar.
class HomeShellScreen extends StatelessWidget {
  final Widget child;
  const HomeShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/')) {
      if (location == '/') return 0;
      if (location.startsWith('/chat')) return 1;
      if (location.startsWith('/orders')) return 2;
      if (location.startsWith('/profile')) return 3;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/chat');
        break;
      case 2:
        context.go('/orders');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
