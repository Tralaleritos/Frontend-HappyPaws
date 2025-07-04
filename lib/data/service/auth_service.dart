import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/user/role.dart';
import 'package:happyp/data/models/user/user.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;
  final UserService _userService = UserService();

  User? get currentUser => _currentUser;

  final String _baseUrl = ApiConstants.AUTH;

  /// Registrar un nuevo usuario
  /// Endpoint: POST /auth/signup
  Future<bool> register(String name, String email, String password, String phone, String role) async {
    try {
      final url = Uri.parse('$_baseUrl/signup');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': name,
          'email': email,
          'password': password,
          'phoneNumber': phone,
          'role': role.toUpperCase(),
        }),
      );

      print('Respuesta registro: ${response.statusCode}');
      print('Cuerpo de respuesta registro: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Registro exitoso: ${responseData.toString()}');
        return true;
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        print('Error 400: ${responseData.toString()}');
        return false;
      } else if (response.statusCode == 409) {
        print('Error 409: Usuario ya existe');
        return false;
      } else {
        print('Error del servidor: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error en registro: $e');
      return false;
    }
  }

  /// Iniciar sesión
  /// Endpoint: POST /auth/login
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Respuesta login: ${response.statusCode}');
      print('Cuerpo de respuesta login: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['token'] != null) {
          final String token = responseData['token'];

          // Guardar el token
          await _saveToken(token);

          // Configurar el token en UserService
          _userService.setAuthToken(token);

          // Obtener información completa del usuario desde el endpoint /users/me
          await _fetchUserInfo();

          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  /// Verificar código de verificación
  /// Endpoint: POST /auth/verify
  Future<bool> verifyCode(String email, String code) async {
    try {
      final url = Uri.parse('$_baseUrl/verify');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'verificationCode': code,
        }),
      );

      print('Verificación: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error al verificar código: $e');
      return false;
    }
  }

  /// Reenviar código de verificación
  /// Endpoint: POST /auth/resend
  Future<bool> resendCode(String email) async {
    try {
      final url = Uri.parse('$_baseUrl/resend?email=$email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Reenvío: ${response.statusCode} - ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error al reenviar código: $e');
      return false;
    }
  }

  /// Actualizar información del usuario
  Future<bool> updateUser({
    String? username,
    String? email,
    String? phoneNumber,
    String? imgUrl,
  }) async {
    if (_currentUser == null) {
      print('No hay usuario autenticado');
      return false;
    }

    try {
      final success = await _userService.updateUser(
        userId: _currentUser!.id,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        imgUrl: imgUrl,
      );

      if (success) {
        // Actualizar la información del usuario local
        await _fetchUserInfo();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al actualizar usuario: $e');
      return false;
    }
  }

  /// Actualizar ubicación del usuario (solo para OWNER)
  Future<bool> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_currentUser == null) {
      print('No hay usuario autenticado');
      return false;
    }

    try {
      final success = await _userService.updateUserLocation(
        userId: _currentUser!.id,
        latitude: latitude,
        longitude: longitude,
      );

      if (success) {
        // Actualizar la información del usuario local
        await _fetchUserInfo();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al actualizar ubicación: $e');
      return false;
    }
  }

  /// Obtener información completa del usuario desde el backend
  Future<void> _fetchUserInfo() async {
    try {
      final user = await _userService.getUser();
      if (user != null) {
        _currentUser = user;
        print('Usuario actualizado desde backend:');
        print('- ID: ${_currentUser?.id}');
        print('- Email: ${_currentUser?.email}');
        print('- Username: ${_currentUser?.username}');
        print('- Roles: ${_currentUser?.role}');
        notifyListeners();
      }
    } catch (e) {
      print('Error al obtener información del usuario: $e');
    }
  }

  /// Guardar token en SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('Token guardado en SharedPreferences');
  }

  /// Verificar si el usuario tiene un rol específico
  bool hasRole(String roleName) {
    if (_currentUser == null) return false;
    return _currentUser!.hasRole(roleName);
  }

  /// Obtener el rol principal como string
  String? get userRole {
    return _currentUser?.role;
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      // Eliminar el token de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');

      // Limpiar el token del UserService
      _userService.clearAuthToken();

      // Limpiar el usuario actual
      _currentUser = null;

      notifyListeners();
      print('Sesión cerrada exitosamente');
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  /// Obtener token desde SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Función para auto-login al iniciar la aplicación
  Future<bool> autoLogin() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Configurar el token en UserService
        _userService.setAuthToken(token);

        // Obtener información del usuario desde el backend
        await _fetchUserInfo();

        return _currentUser != null;
      }
      return false;
    } catch (e) {
      print('Error en auto-login: $e');
      return false;
    }
  }

  /// Hacer solicitudes autenticadas (método legacy para compatibilidad)
  @deprecated
  Future<http.Response> makeAuthenticatedRequest(String endpoint) async {
    String? token = await getToken();

    if (token == null) {
      throw Exception("Token no encontrado. El usuario no está autenticado.");
    }

    final url = Uri.parse('$_baseUrl/$endpoint');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response;
  }

  /// Actualizar el ID del usuario (método legacy para compatibilidad)
  @deprecated
  Future<void> fetchAndSetUserId(UserService userService) async {
    await _fetchUserInfo();
  }
}