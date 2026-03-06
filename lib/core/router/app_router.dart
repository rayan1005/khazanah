import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_screen.dart';
import '../../screens/auth/profile_setup_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/my_posts/my_posts_screen.dart';
import '../../screens/add_post/add_post_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/other_user_profile_screen.dart';
import '../../screens/profile/favorites_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/upgrade_to_boutique_screen.dart';
import '../../screens/post_detail/post_detail_screen.dart';
import '../../screens/boutiques/boutiques_screen.dart';
import '../../screens/boutiques/boutique_store_screen.dart';
import '../../screens/admin/admin_panel_screen.dart';
import '../../screens/admin/manage_categories_screen.dart';
import '../../screens/admin/manage_brands_screen.dart';
import '../../screens/admin/manage_reports_screen.dart';
import '../../screens/admin/manage_users_screen.dart';
import '../../screens/admin/manage_banners_screen.dart';
import '../../screens/admin/manage_home_sections_screen.dart';
import '../../screens/admin/manage_boutique_requests_screen.dart';
import '../../screens/admin/manage_boutiques_screen.dart';
import '../../screens/admin/manage_app_settings_screen.dart';
import '../../screens/boutiques/edit_boutique_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/profile/commission_calculator_screen.dart';
import '../../screens/profile/content_screen.dart';
import '../../screens/profile/support_screen.dart';
import '../../screens/web/web_landing_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// A ChangeNotifier that listens to Firebase auth state changes.
/// Used by GoRouter.refreshListenable to re-evaluate redirects
/// without recreating the entire router.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }
}

final _authNotifier = _AuthNotifier();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;

      // Routes accessible without login (browsing)
      final isPublicRoute = loc == '/home' ||
          loc == '/boutiques' ||
          loc == '/terms' ||
          loc == '/privacy' ||
          loc == '/commission-calculator' ||
          loc == '/welcome' ||
          loc.startsWith('/post/') ||
          loc.startsWith('/boutique/') ||
          loc.startsWith('/user/');

      final isAuthRoute = loc == '/login' ||
          loc == '/otp' ||
          loc == '/profile-setup';

      // Allow public routes without login
      if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute && loc != '/profile-setup') {
        return '/home';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WebLandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/my-posts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MyPostsScreen(),
            ),
          ),
          GoRoute(
            path: '/boutiques',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BoutiquesScreen(),
            ),
          ),
          GoRoute(
            path: '/chats',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Full-screen routes
      GoRoute(
        path: '/add-post',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final postId = state.extra as String?;
          return AddPostScreen(editPostId: postId);
        },
      ),
      GoRoute(
        path: '/post/:postId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/chat/:chatId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatDetailScreen(chatId: chatId);
        },
      ),
      GoRoute(
        path: '/user/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return OtherUserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/favorites',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/commission-calculator',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CommissionCalculatorScreen(),
      ),
      GoRoute(
        path: '/terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ContentScreen(
          title: 'الشروط والأحكام',
          contentSelector: (s) => s.termsAndConditions,
        ),
      ),
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ContentScreen(
          title: 'سياسة الخصوصية',
          contentSelector: (s) => s.privacyPolicy,
        ),
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/upgrade-to-boutique',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UpgradeToBoutiqueScreen(),
      ),
      GoRoute(
        path: '/edit-boutique',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditBoutiqueScreen(),
      ),
      GoRoute(
        path: '/boutique/:userId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return BoutiqueStoreScreen(userId: userId);
        },
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/brands',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageBrandsScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageReportsScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageUsersScreen(),
      ),
      GoRoute(
        path: '/admin/banners',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageBannersScreen(),
      ),
      GoRoute(
        path: '/admin/home-sections',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageHomeSectionsScreen(),
      ),
      GoRoute(
        path: '/admin/boutique-requests',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageBoutiqueRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/boutiques',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageBoutiquesScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ManageAppSettingsScreen(),
      ),
    ],
  );
});
