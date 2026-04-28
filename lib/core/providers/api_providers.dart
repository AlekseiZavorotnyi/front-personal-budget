import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../repositories/auth_repository.dart';
import '../services/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'http://localhost:8080');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRepository(client);
});

final isLoggedInProvider = StateProvider<bool>((ref) {
  final token = TokenStorage.accessToken;
  return token != null && token.isNotEmpty;
});
