import 'package:dio/dio.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio _dio;

  ApiClient._(this._dio);

  factory ApiClient({String? baseUrl}) {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080',
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(AuthInterceptor(dio));

    return ApiClient._(dio);
  }

  Dio get dio => _dio;
}
