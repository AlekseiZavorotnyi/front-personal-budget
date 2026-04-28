class RegisterState {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isLoading;
  final String? error;

  const RegisterState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.error,
  });

  RegisterState copyWith({
    String? name,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isLoading,
    String? error,
  }) {
    return RegisterState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
