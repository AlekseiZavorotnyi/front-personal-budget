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

    if (token != null && token.isNotEmpty && !(isAuthRoute && isPublic)) {
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } else if (isAuthRoute && isPublic) {
      handler.next(options);
    } else {
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refresh = TokenStorage.refreshToken;

      if (refresh == null || refresh.isEmpty) {
        TokenStorage.clear();
        return handler.reject(err);
      }

      try {
        final refreshResp = await dio.post(
          '/api/auth/refresh',
          data: {'refreshToken': refresh},
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final newAccess = refreshResp.data['tokens']['accessToken'];
        final newRefresh = refreshResp.data['tokens']['refreshToken'];

        await TokenStorage.saveTokens(newAccess, newRefresh);

        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';

        final retryResponse = await dio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        TokenStorage.clear();
        return handler.reject(err);
      }
    }

    handler.next(err);
  }
}