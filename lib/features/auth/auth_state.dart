class AuthState {
  final String email;
  final String password;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
