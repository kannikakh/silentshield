import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserService {
  static const _key = 'local_users_map';

  /// Returns a map of email -> password
  static Future<Map<String, String>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final Map<String, dynamic> m = jsonDecode(raw);
    return m.map((k, v) => MapEntry(k, v.toString()));
  }

  static Future<void> saveUsers(Map<String, String> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(users));
  }

  static Future<void> addUser(String email, String password) async {
    final users = await loadUsers();
    users[email] = password;
    await saveUsers(users);
  }

  static Future<bool> validate(String email, String password) async {
    final users = await loadUsers();
    return users.containsKey(email) && users[email] == password;
  }

  static Future<bool> hasUser(String email) async {
    final users = await loadUsers();
    return users.containsKey(email);
  }
}
