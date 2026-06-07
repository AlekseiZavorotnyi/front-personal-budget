import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/auth_models.dart';
import '../../core/providers/api_providers.dart';
import '../../core/services/token_storage.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/local_budget_cache.dart';
import '../transactions/transactions_providers.dart';
import '../transactions/categories_providers.dart';
import '../stats/stats_providers.dart';
import 'auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
      (ref) => AuthController(ref),
);

class AuthController extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthController(this._ref) : super(const AuthState());

  void setEmail(String email) {
    state = state.copyWith(email: email, error: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, error: null);
  }

  Future<bool> login(BuildContext context) async {
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(error: 'Заполните все поля');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(authRepositoryProvider);

      final session = await repo.login(
        LoginRequest(
          email: state.email.trim().toLowerCase(),
          password: state.password,
        ),
      );

      await TokenStorage.saveTokens(
        session.tokens.accessToken,
        session.tokens.refreshToken,
      );

      _ref.read(isLoggedInProvider.notifier).state = true;

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        context.go('/');
      }

      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();

      state = state.copyWith(
        isLoading: false,
        error: msg ?? 'Ошибка авторизации',
      );

      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось выполнить вход',
      );
      return false;
    }
  }

  Future<void> logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Выход из аккаунта"),
        content: const Text("Вы уверены, что хотите выйти? Все локальные данные будут очищены."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Выйти"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    _ref.read(isLoggedInProvider.notifier).state = false;

    await CacheService.clearAllCache();
    await CacheService.closeAllBoxes();
    TokenStorage.clear();

    _ref.invalidate(transactionsProvider);
    _ref.invalidate(balanceProvider);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(statsSummaryProvider);
    _ref.invalidate(statsByCategoryProvider);
    _ref.invalidate(statsMonthlyProvider);
    _ref.invalidate(transactionFiltersProvider);

    if (context.mounted) {
      context.go('/login');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы вышли из аккаунта')),
      );
    }
  }
}