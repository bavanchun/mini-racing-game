import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Service lưu trữ người dùng (tính năng bonus).
///
/// Sử dụng SharedPreferences để lưu danh sách người dùng dưới dạng JSON.
/// Mọi phương thức fail soft: nếu storage không khả dụng thì game vẫn hoạt động.
class UserStorage {
  UserStorage._();

  static const String _usersKey = 'users_list';
  static const String _currentUserKey = 'current_user';

  /// Lấy danh sách tất cả người dùng.
  static Future<List<User>> getUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      if (usersJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(usersJson);
      return decoded.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Lưu danh sách người dùng.
  static Future<void> saveUsers(List<User> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = jsonEncode(users.map((u) => u.toJson()).toList());
      await prefs.setString(_usersKey, usersJson);
    } catch (_) {
      // ignore: persistence là tính năng bonus, không bao giờ chặn gameplay.
    }
  }

  /// Đăng ký người dùng mới. Trả về true nếu thành công, false nếu username đã tồn tại.
  static Future<bool> register(User user) async {
    try {
      final users = await getUsers();
      
      // Kiểm tra username đã tồn tại chưa
      if (users.any((u) => u.username == user.username)) {
        return false;
      }
      
      users.add(user);
      await saveUsers(users);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Đăng nhập. Trả về User nếu thành công, null nếu thất bại.
  static Future<User?> login(String username, String password) async {
    try {
      final users = await getUsers();
      final user = users.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => users.isEmpty ? User(username: '', password: '', createdAt: DateTime.now()) : users.first,
      );
      
      if (user.username == username && user.password == password) {
        // Lưu user hiện tại
        await setCurrentUser(user);
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lưu user hiện đang đăng nhập.
  static Future<void> setCurrentUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
    } catch (_) {
      // ignore: persistence là tính năng bonus.
    }
  }

  /// Lấy user hiện đang đăng nhập.
  static Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      if (userJson == null) return null;
      
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Đăng xuất - xóa user hiện tại.
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
    } catch (_) {
      // ignore: persistence là tính năng bonus.
    }
  }

  /// Cập nhật ví của user.
  static Future<void> updateUserWallet(String username, int newWallet) async {
    try {
      final users = await getUsers();
      final index = users.indexWhere((u) => u.username == username);
      if (index != -1) {
        users[index] = users[index].copyWith(wallet: newWallet);
        await saveUsers(users);
        
        // Cập nhật cả user hiện tại nếu đang đăng nhập
        final currentUser = await getCurrentUser();
        if (currentUser?.username == username) {
          await setCurrentUser(users[index]);
        }
      }
    } catch (_) {
      // ignore: persistence là tính năng bonus.
    }
  }
}
