import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/auth/auth_models.dart';
import '../services/token_storage.dart';

class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  Future<AuthSessionResponse> login(LoginRequest request) async {
    final response = await _client.dio.post(
      '/api/auth/login',
      data: request.toJson(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: response.data.toString(),
      );
    }

    final session = AuthSessionResponse.fromJson(response.data);
    TokenStorage.saveTokens(
      session.tokens.accessToken,
      session.tokens.refreshToken,
    );

    return session;
  }

  Future<AuthSessionResponse> register(RegisterRequest request) async {
    final response = await _client.dio.post(
      '/api/auth/register',
      data: request.toJson(),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: response.data.toString(),
      );
    }

    final session = AuthSessionResponse.fromJson(response.data);
    TokenStorage.saveTokens(
      session.tokens.accessToken,
      session.tokens.refreshToken,
    );

    return session;
  }
}
