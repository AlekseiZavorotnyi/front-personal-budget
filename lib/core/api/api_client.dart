import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio _dio;

  ApiClient._(this._dio);

  factory ApiClient({String? baseUrl}) {
    final resolvedBaseUrl = baseUrl ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:8080',
        );

    final dio = Dio(BaseOptions(
      baseUrl: resolvedBaseUrl,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor(dio));

    return ApiClient._(dio);
  }

  Dio get dio => _dio;
}
