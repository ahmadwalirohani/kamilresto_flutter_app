import 'user.dart';

class AuthRequest {
  const AuthRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    return {'name': username, 'password': password};
  }
}

class AuthResponse {
  const AuthResponse({required this.user, required this.token});

  final User user;
  final String token;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final token = data['accessToken'] as String? ??
        data['token'] as String? ??
        json['accessToken'] as String? ??
        json['token'] as String? ??
        '';
    final userJson = data['userData'] is Map<String, dynamic>
        ? data['userData'] as Map<String, dynamic>
        : data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;
    return AuthResponse(
      user: User.fromJson({...userJson, 'token': token}),
      token: token,
    );
  }
}
