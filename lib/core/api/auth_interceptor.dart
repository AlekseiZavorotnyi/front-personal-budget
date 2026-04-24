import 'package:dio/dio.dart';
import '../services/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;

  AuthInterceptor(this.dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = TokenStorage.accessToken;

    final isAuthRoute = options.path.startsWith('/api/auth/');
    final isPublic = options.path.endsWith('/login') ||
        options.path.endsWith('/register') ||
        options.path.endsWith('/refresh');

    if (token != null && !(isAuthRoute && isPublic)) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }


  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refresh = TokenStorage.refreshToken;
      if (refresh == null) {
        return handler.reject(err);
      }

      try {
        final refreshResp = await dio.post('/api/auth/refresh', data: {
          'refreshToken': refresh,
        });

        final newAccess = refreshResp.data['tokens']['accessToken'];
        final newRefresh = refreshResp.data['tokens']['refreshToken'];

        TokenStorage.saveTokens(newAccess, newRefresh);

        final retry = await dio.request(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: Options(
            method: err.requestOptions.method,
            headers: {
              ...err.requestOptions.headers,
              'Authorization': 'Bearer $newAccess',
            },
          ),
        );

        return handler.resolve(retry);
      } catch (_) {
        TokenStorage.clear();
        return handler.reject(err);
      }
    }

    return handler.reject(err);
  }
}
