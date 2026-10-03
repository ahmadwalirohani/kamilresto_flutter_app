class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.token,
  });

  final String id;
  final String name;
  final String username;
  final String role;
  final String token;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? json['name'] as String? ?? json['email'] as String? ?? '',
      role: json['role'] as String? ?? ((json['is_admin'] == 1 || json['is_admin'] == true) ? 'Admin' : 'Waiter'),
      token: json['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
      'token': token,
    };
  }
}
