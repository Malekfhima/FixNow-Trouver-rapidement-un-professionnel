import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fixnow/services/firebase_auth_service.dart';
import 'package:fixnow/features/auth/login_screen.dart';
import 'package:fixnow/features/auth/register_screen.dart';
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

/// Route path constants.
class RoutePaths {
  RoutePaths._();

  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const phoneAuth = '/phone-auth';
  static const home = '/';
  static const search = '/search';
  static const proProfile = '/pro/:proId';
  static const booking = '/booking/:requestId';
  static const chatList = '/chat';
  static const chatDetail = '/chat/:chatId';
  static const orders = '/orders';
  static const profile = '/profile';
}

/// App router provider — uses GoRouter with auth redirect.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnboarding = state.matchedLocation == RoutePaths.onboarding;
      final isAuthRoute =
          state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.register ||
          state.matchedLocation == RoutePaths.phoneAuth;

      // If not logged in and not on an auth page, send to login
      // (skip redirect when Firebase is not configured)
      if (!isLoggedIn && !isOnboarding && !isAuthRoute) {
        return null; // Show the page directly for now
      }

      // If logged in and on login/register, send to home
      if (isLoggedIn && isAuthRoute) {
        return RoutePaths.home;
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
    ],
  );
});
