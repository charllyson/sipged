class LoginData {
  final String email;
  final String password;
  final String? selectedArea;

  const LoginData({
    this.email = '',
    this.password = '',
    this.selectedArea,
  });

  LoginData copyWith({
    String? email,
    String? password,
    String? selectedArea,
  }) {
    return LoginData(
      email: email ?? this.email,
      password: password ?? this.password,
      selectedArea: selectedArea ?? this.selectedArea,
    );
  }
}
