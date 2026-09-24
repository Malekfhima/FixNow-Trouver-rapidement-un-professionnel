import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/core/config/app_runtime.dart';
import 'package:fixnow/features/home/home_controller.dart';
import 'package:fixnow/models/user_model.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/features/chat/chat_controller.dart';
import 'package:fixnow/features/auth/login_screen.dart';
import 'package:fixnow/features/auth/register_screen.dart';
import 'package:fixnow/features/auth/forgot_password_screen.dart';
import 'package:fixnow/features/auth/phone_auth_screen.dart';
import 'package:fixnow/features/onboarding/onboarding_screen.dart';
import 'package:fixnow/features/home/home_shell_screen.dart';
import 'package:fixnow/features/home/home_screen.dart';
import 'package:fixnow/features/search/search_screen.dart';
import 'package:fixnow/features/professional_profile/pro_profile_screen.dart';
import 'package:fixnow/features/booking/booking_screen.dart';
import 'package:fixnow/features/chat/chat_list_screen.dart';
import 'package:fixnow/features/chat/chat_detail_screen.dart';
import 'package:fixnow/features/client_dashboard/orders_screen.dart';
import 'package:fixnow/features/profile/profile_screen.dart';
import 'package:fixnow/features/profile/profile_edit_screen.dart';
import 'package:fixnow/features/review/review_screen.dart';
import 'package:fixnow/features/notifications/notifications_screen.dart';
import 'package:fixnow/features/admin/admin_screen.dart';
import 'package:fixnow/features/pro_dashboard/pro_requests_screen.dart';
import 'package:fixnow/features/pro_dashboard/pro_profile_edit_screen.dart';
import 'package:fixnow/features/profile/debug_seed_screen.dart';

/// Route path constants.
class RoutePaths {
  RoutePaths._();

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const phoneAuth = '/phone-auth';
  static const home = '/';
  static const search = '/search';
  static const proProfile = '/pro/:proId';
  static const booking = '/booking/:requestId';
  static const chatList = '/chat';
  static const chatDetail = '/chat/:chatId';
  static const orders = '/orders';
  static const profile = '/profile';
  static const newChat = '/chat/new';
  static const bookingNew = '/booking/new';
  static const notifications = '/notifications';
  static const profileEdit = '/profile/edit';
  static const review = '/review/:requestId';
  static const admin = '/admin';
}

/// Routes reserved to professional accounts.
const proOnlyRoutes = ['/pro-dashboard', '/pro-profile-edit'];

/// Routes reserved to admin accounts.
const adminOnlyRoutes = ['/admin'];

/// App router provider — uses GoRouter with role-based auth redirect.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);

  // Resolve the signed-in user's capabilities (null when logged out).
  final user = profileAsync.valueOrNull;
  final UserRole? role = user?.role;
  final bool isPro = user?.isPro ?? false;
  final isLoggedIn = authState.valueOrNull != null;

  // While the Firestore profile is loading for a signed-in user, render the
  // current route without redirecting (avoids flicker to /login).
  final profileLoading = isLoggedIn && profileAsync.isLoading;

  return GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isOnboarding = location == RoutePaths.onboarding;
      final isAuthRoute =
          location == RoutePaths.login ||
          location == RoutePaths.register ||
          location == RoutePaths.forgotPassword ||
          location == RoutePaths.phoneAuth;

      // Firebase not configured: leave everything accessible (dev mode).
      if (!firebaseInitialized) return null;

      // Not logged in: only auth pages and onboarding are reachable.
      if (!isLoggedIn) {
        if (!isAuthRoute && !isOnboarding) {
          return RoutePaths.login;
        }
        return null;
      }

      // Logged in: keep auth pages out of the way until the profile is known.
      if (profileLoading) return null;
      if (isAuthRoute) return RoutePaths.home;

      // Role-based guards (rules Firestore remain the real enforcement).
      final isProRoute = proOnlyRoutes.any((p) => location.startsWith(p));
      final isAdminRoute = adminOnlyRoutes.any((p) => location.startsWith(p));
      // A pro account keeps all client capabilities (dual role).
      if (isProRoute && !isPro) return RoutePaths.home;
      if (isAdminRoute && role != UserRole.admin) return RoutePaths.home;
      if (location.startsWith(RoutePaths.review.split(':').first) &&
          !isLoggedIn) {
        return RoutePaths.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.phoneAuth,
        builder: (context, state) => const PhoneAuthScreen(),
      ),

      // Shell route with bottom navigation
      ShellRoute(
        builder: (context, state, child) => HomeShellScreen(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.chatList,
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: RoutePaths.orders,
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: RoutePaths.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.proProfile,
        builder: (context, state) {
          final proId = state.pathParameters['proId']!;
          return ProProfileScreen(proId: proId);
        },
      ),
      GoRoute(
        path: RoutePaths.booking,
        builder: (context, state) {
          final requestId = state.pathParameters['requestId'];
          return BookingScreen(requestId: requestId);
        },
      ),
      GoRoute(
        path: RoutePaths.chatDetail,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatDetailScreen(chatId: chatId);
        },
      ),

      // Notifications (in-app)
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Client profile editing
      GoRoute(
        path: RoutePaths.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),

      // Review (rate a completed request)
      GoRoute(
        path: RoutePaths.review,
        builder: (context, state) {
          final requestId = state.pathParameters['requestId']!;
          return ReviewScreen(requestId: requestId);
        },
      ),

      // Admin dashboard
      GoRoute(
        path: RoutePaths.admin,
        builder: (context, state) => const AdminScreen(),
      ),

      // Pro-only routes (guarded by role redirect + Firestore rules).
      GoRoute(
        path: '/pro-dashboard',
        builder: (context, state) => const ProRequestsScreen(),
      ),
      GoRoute(
        path: '/pro-profile-edit',
        builder: (context, state) => const ProProfileEditScreen(),
      ),

      // Dev-only demo data seeder (debug builds).
      GoRoute(
        path: '/debug-seed',
        builder: (context, state) => const DebugSeedScreen(),
      ),

      // New chat creation (client -> pro). We reuse the chat list and a helper create route.
      GoRoute(
        path: RoutePaths.newChat,
        builder: (context, state) {
          return const _NewChatScreen();
        },
      ),
    ],
  );
});

/// Simple screen that creates (or finds) a chat with a pro and redirects to it.
class _NewChatScreen extends ConsumerStatefulWidget {
  const _NewChatScreen();

  @override
  ConsumerState<_NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<_NewChatScreen> {
  @override
  void initState() {
    super.initState();
    _createChat();
  }

  Future<void> _createChat() async {
    final proId = GoRouterState.of(context).uri.queryParameters['proId'];
    if (proId == null) {
      context.go('/chat');
      return;
    }

    try {
      final chatId = await ensureChatBetween(proId: proId, ref: ref);
      if (!mounted) return;
      if (chatId != null) {
        context.go('/chat/$chatId');
      } else {
        // If no user logged in, go back.
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
