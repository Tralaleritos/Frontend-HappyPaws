import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/nueva/user_model.dart';


class StorageManager {
  static const String KEY_TOKEN = 'auth_token';
  static const String KEY_USER = 'user_data';

  // Guardar token de autenticación
  static Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(KEY_TOKEN, token);
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KEY_TOKEN);
  }

  // Guardar datos del usuario
  static Future<bool> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(KEY_USER, jsonEncode(user.toJson()));
  }

  // Obtener datos del usuario
  static Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(KEY_USER);

    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Limpiar todos los datos (para el cierre de sesión)
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }
}