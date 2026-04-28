class RegisterRequest {
  final String? name;
  final String? email;
  final String? password;

  RegisterRequest({this.name, this.email, this.password});

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'password': password,
  };
}

class LoginRequest {
  final String? email;
  final String? password;

  LoginRequest({this.email, this.password});

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
  };
}

class UserProfileResponse {
  final String id;
  final String name;
  final String email;
  final String currency;
  final String timezone;
  final bool mocked;

  UserProfileResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.timezone,
    required this.mocked,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      currency: json['currency'] as String,
      timezone: json['timezone'] as String,
      mocked: json['mocked'] as bool? ?? false,
    );
  }
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final bool mocked;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    required this.mocked,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSeconds: (json['expiresInSeconds'] as num).toInt(),
      mocked: json['mocked'] as bool? ?? false,
    );
  }
}

class AuthSessionResponse {
  final UserProfileResponse user;
  final TokenPair tokens;
  final bool mocked;

  AuthSessionResponse({
    required this.user,
    required this.tokens,
    required this.mocked,
  });

  factory AuthSessionResponse.fromJson(Map<String, dynamic> json) {
    return AuthSessionResponse(
      user: UserProfileResponse.fromJson(json['user'] as Map<String, dynamic>),
      tokens: TokenPair.fromJson(json['tokens'] as Map<String, dynamic>),
      mocked: json['mocked'] as bool? ?? false,
    );
  }
}
