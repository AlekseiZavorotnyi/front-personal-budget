import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/auth/auth_models.dart';
import '../../core/providers/api_providers.dart';
import 'register_state.dart';

final registerControllerProvider =
StateNotifierProvider<RegisterController, RegisterState>(
      (ref) => RegisterController(ref),
);

class RegisterController extends StateNotifier<RegisterState> {
  final Ref _ref;

  RegisterController(this._ref) : super(const RegisterState());

  void setName(String value) {
    state = state.copyWith(name: value, error: null);
  }

  void setEmail(String value) {
    state = state.copyWith(email: value, error: null);
  }

  void setPassword(String value) {
    state = state.copyWith(password: value, error: null);
  }

  void setConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, error: null);
  }

  Future<bool> register(BuildContext context) async {
    if (state.email.isEmpty ||
        state.password.isEmpty ||
        state.confirmPassword.isEmpty) {
      state = state.copyWith(error: 'Заполните все поля');
      return false;
    }

    if (state.password.length < 8) {
      state = state.copyWith(error: 'Пароль должен быть не менее 8 символов');
      return false;
    }

    if (state.password != state.confirmPassword) {
      state = state.copyWith(error: 'Пароли не совпадают');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(authRepositoryProvider);

      await repo.register(
        RegisterRequest(
          name: state.name.isEmpty ? null : state.name,
          email: state.email.trim().toLowerCase(),
          password: state.password,
        ),
      );

      state = state.copyWith(isLoading: false);

      if (context.mounted) {
        context.go('/login');
      }

      return true;
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString();

      state = state.copyWith(
        isLoading: false,
        error: msg ?? 'Ошибка регистрации',
      );

      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось выполнить регистрацию',
      );
      return false;
    }
  }
}
