import 'dart:html' as html;

class TokenStorage {
  static const _accessKey = 'accessToken';
  static const _refreshKey = 'refreshToken';

  static Future<void> saveTokens(String access, String refresh) async {
    html.window.localStorage[_accessKey] = access;
    html.window.localStorage[_refreshKey] = refresh;
  }

  static String? get accessToken =>
      html.window.localStorage[_accessKey];

  static String? get refreshToken =>
      html.window.localStorage[_refreshKey];

  static void clear() {
    html.window.localStorage.remove(_accessKey);
    html.window.localStorage.remove(_refreshKey);
  }

  static bool get hasTokens =>
      accessToken != null && accessToken!.isNotEmpty;
}