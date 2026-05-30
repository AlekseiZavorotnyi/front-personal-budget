import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/transactions/add_transaction_page.dart';
import '../../features/transactions/home_page.dart';
import '../../features/transactions/сategories_page.dart';
import '../providers/api_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',

    redirect: (context, state) {
      final loggedIn = ref.watch(isLoggedInProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !loggingIn) {
        return '/login';
      }

      if (loggedIn && loggingIn) {
        return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/add',
        builder: (context, state) => const AddTransactionPage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesPage(),
      ),
    ],
  );
});
