import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/login_page.dart';
import '../../features/transactions/home_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
  ],
);
