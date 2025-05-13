import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  // URL de tu backend
  final String _baseUrl = 'http://10.0.2.2:5000/api/v1/auth';

  // Función para registrar un nuevo usuario
  Future<bool> register(String name, String email, String password, String phone, String role) async {
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

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      // Si el registro devuelve un token similar al login
      if (responseData['token'] != null) {
        await _saveToken(responseData['token']);
        _extractUserFromToken(responseData['token']);
        return true;
      } else if (responseData['user'] != null) {
        // Si el registro devuelve un objeto de usuario directamente
        _currentUser = User.fromJson(responseData['user']);
        return true;
      }
    }
    return false;
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

      // Para depuración
      print('Respuesta API: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Para depuración
        print('JSON decodificado:');
        final encoder = JsonEncoder.withIndent('  ');
        print(encoder.convert(responseData));

        // Verificar si hay un token en la respuesta
        if (responseData['token'] != null) {
          final String token = responseData['token'];

          // Guardar el token en SharedPreferences
          await _saveToken(token);

          // Extraer datos del usuario del token JWT
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

  // Método para guardar el token en SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    print('Token guardado en SharedPreferences');
  }

  // Método para extraer información del usuario del token JWT
  bool _extractUserFromToken(String token) {
    try {
      // El token JWT tiene tres partes separadas por puntos
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Formato de token inválido');
        return false;
      }

      // Decodificar la parte del payload (segunda parte)
      String payload = parts[1];

      // Ajustar la longitud para que sea múltiplo de 4
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      // Decodificar el payload de base64
      final normalized = base64Url.normalize(payload);
      final decodedPayload = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decodedPayload);

      print('Payload decodificado: $payloadMap');

      // Extraer información del usuario del payload
      final String email = payloadMap['sub'] ?? '';
      List<String> roleNames = [];

      // Extraer roles del token
      if (payloadMap['ROLES'] != null && payloadMap['ROLES'] is List) {
        roleNames = List<String>.from(payloadMap['ROLES']);
      }

      // Crear lista de roles a partir de los nombres
      List<Role> roles = roleNames.asMap().entries.map((entry) {
        return Role(id: entry.key + 1, name: entry.value);
      }).toList();

      // Crear usuario con la información extraída
      _currentUser = User(
        username: email.split('@').first, // Usar la parte del email antes de @ como username
        email: email,
        password: '', // No guardamos la contraseña
        phoneNumber: '', // No hay número de teléfono en el token
        roles: roles,
      );

      print('Usuario extraído del token:');
      print('- Email: ${_currentUser?.email}');
      print('- Roles: ${_currentUser?.roles.map((r) => "${r.id}:${r.name}").join(", ")}');

      return true;
    } catch (e) {
      print('Error al decodificar el token: $e');
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



  // Método para verificar si el usuario tiene un rol específico
  bool hasRole(String roleName) {
    if (_currentUser == null) return false;
    return _currentUser!.hasRole(roleName);
  }

  // Obtener el rol principal como string
  String? get userRole {
    return _currentUser?.role;
  }

  // Función para cerrar sesión
  Future<void> logout() async {
    // Elimina el token de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');

    _currentUser = null;
    notifyListeners();
  }

  // Función para obtener el token desde SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Función para hacer solicitudes autenticadas
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

  // Función para verificar si hay un token guardado y cargar los datos del usuario
  Future<bool> autoLogin() async {
    final token = await getToken();
    if (token != null) {
      return _extractUserFromToken(token);
    }
    return false;
  }

  Future<void> addDefaultUsers() async {
    // Si deseas agregar usuarios por defecto, implementa la lógica aquí.
    print("Añadiendo usuarios por defecto...");
    // O bien, crear un usuario de manera local:
    await register("Usuario Demo", "demo@correo.com", "123456", "123456789", "USER");
  }
}