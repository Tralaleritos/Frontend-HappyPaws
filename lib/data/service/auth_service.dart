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

  User? get currentUser => _currentUser;

  final String _baseUrl = ApiConstants.AUTH;

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

        if (responseData['token'] != null) {
          await _saveToken(responseData['token']);
          _extractUserFromToken(responseData['token']);
          return true;
        } else {
          return true;
        }
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        print('Error 400: ${responseData['message'] ?? 'Error de validación'}');
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

      print('Respuesta API: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['token'] != null) {
          final String token = responseData['token'];
          await _saveToken(token);

          bool success = _extractUserFromToken(token);
          if (success) {
            notifyListeners();
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('Token guardado en SharedPreferences');
  }

  // 🔥 MÉTODO MEJORADO PARA EXTRAER ROL DEL TOKEN
  bool _extractUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Formato de token inválido');
        return false;
      }

      String payload = parts[1];
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final normalized = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decodedPayload);

      print('Payload decodificado: $payloadMap');

      // Extraer información básica
      final String email = payloadMap['sub'] ?? '';
      final String userId = payloadMap['userId']?.toString() ?? '';
      final String username = payloadMap['username'] ?? email.split('@').first;

      // 🎯 EXTRAER ROL DEL TOKEN - Múltiples formas posibles
      String? primaryRole;
      List<String> roleNames = [];

      // Opción 1: Campo 'ROLES' como lista
      if (payloadMap['ROLES'] != null && payloadMap['ROLES'] is List) {
        roleNames = List<String>.from(payloadMap['ROLES']);
        primaryRole = roleNames.isNotEmpty ? roleNames.first : null;
      }
      // Opción 2: Campo 'role' como string
      else if (payloadMap['role'] != null) {
        primaryRole = payloadMap['role'].toString();
        roleNames = [primaryRole];
      }
      // Opción 3: Campo 'authorities' (Spring Security)
      else if (payloadMap['authorities'] != null && payloadMap['authorities'] is List) {
        roleNames = List<String>.from(payloadMap['authorities']);
        primaryRole = roleNames.isNotEmpty ? roleNames.first : null;
      }
      // Opción 4: Valor por defecto
      else {
        primaryRole = 'USER';
        roleNames = ['USER'];
        print('⚠️ No se encontró rol en el token, usando valor por defecto: USER');
      }

      // Crear lista de roles
      List<Role> roles = roleNames.asMap().entries.map((entry) {
        return Role(id: entry.key + 1, name: entry.value);
      }).toList();

      // Crear usuario con rol extraído del token
      _currentUser = User(
        id: userId,
        username: username,
        email: email,
        password: '',
        phoneNumber: payloadMap['phoneNumber']?.toString() ?? '',
        roles: roles,
        offers: [], // INICIALIZA AQUÍ LA LISTA VACÍA
      );

      print('✅ Usuario extraído del token:');
      print('- ID: ${_currentUser?.id}');
      print('- Email: ${_currentUser?.email}');
      print('- Username: ${_currentUser?.username}');
      print('- Rol principal: $primaryRole');
      print('- Todos los roles: ${roleNames.join(", ")}');

      return true;
    } catch (e) {
      print('❌ Error al decodificar el token: $e');
      return false;
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    final url = Uri.parse('$_baseUrl/verify');

    try {
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

  Future<bool> resendCode(String email) async {
    final url = Uri.parse('$_baseUrl/resend?email=$email');

    try {
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

  // 🎯 MÉTODOS MEJORADOS PARA ACCEDER AL ROL
  bool hasRole(String roleName) {
    if (_currentUser == null) return false;
    return _currentUser!.hasRole(roleName);
  }

  // Obtener el rol principal como string
  String? get userRole {
    if (_currentUser == null) return null;

    // Si tu modelo User tiene un campo 'role' directo:
    // return _currentUser!.role;

    // Si solo tienes la lista de roles:
    return _currentUser!.roles.isNotEmpty ? _currentUser!.roles.first.name : null;
  }

  // Obtener todos los roles como lista de strings
  List<String> get userRoles {
    if (_currentUser == null) return [];
    return _currentUser!.roles.map((role) => role.name).toList();
  }

  // Verificar si tiene un rol específico (case-insensitive)
  bool hasRoleIgnoreCase(String roleName) {
    if (_currentUser == null) return false;
    return _currentUser!.roles.any(
            (role) => role.name.toUpperCase() == roleName.toUpperCase()
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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

  // 🔄 MÉTODOS PARA ACTUALIZAR USUARIO
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
      final userService = UserService();
      final token = await getToken();
      if (token != null) {
        userService.setAuthToken(token);
      }

      final success = await userService.updateUser(
        userId: _currentUser!.id,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        imgUrl: imgUrl,
      );

      if (success) {
        // Actualizar información local del usuario
        _currentUser = _currentUser!.copyWith(
          username: username ?? _currentUser!.username,
          email: email ?? _currentUser!.email,
          phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
          // imgUrl: imgUrl ?? _currentUser!.imgUrl, // Si tu modelo User tiene imgUrl
        );
        notifyListeners();
        print('✅ Usuario actualizado exitosamente');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error al actualizar usuario: $e');
      return false;
    }
  }

  // 📍 ACTUALIZAR UBICACIÓN DEL USUARIO (solo para OWNER)
  Future<bool> updateUserLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_currentUser == null) {
      print('No hay usuario autenticado');
      return false;
    }

    // Verificar si el usuario tiene rol OWNER
    if (!hasRoleIgnoreCase('OWNER')) {
      print('❌ Solo los usuarios con rol OWNER pueden actualizar ubicación');
      return false;
    }

    try {
      final userService = UserService();
      final token = await getToken();
      if (token != null) {
        userService.setAuthToken(token);
      }

      final success = await userService.updateUserLocation(
        userId: _currentUser!.id,
        latitude: latitude,
        longitude: longitude,
      );

      if (success) {
        print('✅ Ubicación actualizada exitosamente');
        print('📍 Latitud: $latitude, Longitud: $longitude');

        // Aquí podrías actualizar el usuario local si tienes campos de ubicación
        // _currentUser = _currentUser!.copyWith(
        //   latitude: latitude,
        //   longitude: longitude,
        // );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error al actualizar ubicación: $e');
      return false;
    }
  }

  Future<void> fetchAndSetUserId(UserService userService) async {
    try {
      final token = await getToken();
      if (token == null) return;

      userService.setAuthToken(token);
      final userWithId = await userService.getUser();

      if (_currentUser != null && userWithId != null) {
        _currentUser = _currentUser!.copyWith(id: userWithId.id);
        notifyListeners();
        print('ID del usuario actualizado: ${_currentUser?.id}');
      }
    } catch (e) {
      print('Error al actualizar el ID del usuario: $e');
    }
  }

  Future<bool> autoLogin() async {
    final token = await getToken();
    if (token != null) {
      bool success = _extractUserFromToken(token);
      if (success) {
        notifyListeners();
      }
      return success;
    }
    return false;
  }
}