/// Model người dùng cho hệ thống đăng nhập/đăng ký.
class User {
  final String username;
  final String password;
  final int wallet;
  final DateTime createdAt;

  const User({
    required this.username,
    required this.password,
    this.wallet = 100,
    required this.createdAt,
  });

  /// Tạo User từ JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String,
      password: json['password'] as String,
      wallet: json['wallet'] as int? ?? 100,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Chuyển User sang JSON
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'wallet': wallet,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Tạo bản sao với ví mới
  User copyWith({int? wallet}) {
    return User(
      username: username,
      password: password,
      wallet: wallet ?? this.wallet,
      createdAt: createdAt,
    );
  }
}
