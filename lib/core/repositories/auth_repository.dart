import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/auth_models.dart';

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

    return AuthSessionResponse.fromJson(response.data);
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

    return AuthSessionResponse.fromJson(response.data);
  }
}