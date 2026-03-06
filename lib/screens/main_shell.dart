import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_strings.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/home') return 0;
    if (location == '/boutiques') return 1;
    if (location == '/chats') return 3;
    if (location == '/profile') return 4;
    return 0;
  }

  /// Check if user is logged in; if not, redirect to login
  bool _requireLogin(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      context.push('/login');
      return false;
    }
    return true;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/boutiques');
      case 2:
        if (_requireLogin(context)) context.push('/add-post');
      case 3:
        if (_requireLogin(context)) context.go('/chats');
      case 4:
        if (_requireLogin(context)) context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_post_fab',
        onPressed: () {
          if (_requireLogin(context)) context.push('/add-post');
        },
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
            icon: Icon(Icons.storefront_rounded),
            label: AppStrings.boutiques,
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
