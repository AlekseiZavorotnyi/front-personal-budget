import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'register_controller.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registerControllerProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Регистрация',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),

                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Имя (необязательно)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref
                      .read(registerControllerProvider.notifier)
                      .setName(value),
                ),
                const SizedBox(height: 16),

                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref
                      .read(registerControllerProvider.notifier)
                      .setEmail(value),
                ),
                const SizedBox(height: 16),

                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref
                      .read(registerControllerProvider.notifier)
                      .setPassword(value),
                ),
                const SizedBox(height: 16),

                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Повторите пароль',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => ref
                      .read(registerControllerProvider.notifier)
                      .setConfirmPassword(value),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isLoading
                        ? null
                        : () async {
                      final success = await ref
                          .read(registerControllerProvider.notifier)
                          .register(context);

                      if (success && context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: state.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Создать аккаунт'),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('У меня уже есть аккаунт'),
                ),

                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
