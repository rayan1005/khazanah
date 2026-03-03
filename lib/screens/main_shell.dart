import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/home') return 0;
    if (location == '/my-posts') return 1;
    if (location == '/chats') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/my-posts');
      case 2:
        context.push('/add-post');
      case 3:
        context.go('/chats');
      case 4:
        context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_post_fab',
        onPressed: () => context.push('/add-post'),
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_rounded),
            label: AppStrings.myPosts,
          ),
          BottomNavigationBarItem(
            icon: SizedBox.shrink(), // Placeholder for FAB
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_rounded),
            label: AppStrings.chats,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppStrings.profile,
          ),
        ],
      ),
    );
  }
}
