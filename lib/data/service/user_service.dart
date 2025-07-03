import 'dart:convert';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/user/user.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String _baseUrl = ApiConstants.BASE_URL;
  String? _token;

  void setAuthToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final baseHeaders = {'Content-Type': 'application/json'};
    if (_token != null) {
      baseHeaders['Authorization'] = 'Bearer $_token';
    }
    return baseHeaders;
  }

  /// Obtener información del usuario autenticado
  /// Endpoint: GET /users/me
  Future<User?> getUser() async {
    try {
      final url = Uri.parse('$_baseUrl/users/me');
      final response = await http.get(url, headers: _headers);

      print('Get user response: ${response.statusCode}');
      print('Get user body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return User.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado');
        return null;
      } else {
        throw Exception('Failed to load user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error al obtener usuario: $e');
      return null;
    }
  }

  /// Obtener ID del usuario autenticado
  Future<String?> getUserId() async {
    try {
      final user = await getUser();
      return user?.id;
    } catch (e) {
      print('Error al obtener ID del usuario: $e');
      return null;
    }
  }

  /// Actualizar información del usuario
  /// Endpoint: PUT /users/{id}
  Future<bool> updateUser({
    required String userId,
    String? username,
    String? email,
    String? phoneNumber,
    String? imgUrl,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId');

      // Crear el cuerpo de la petición solo con los campos no nulos
      final Map<String, dynamic> body = {};
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (imgUrl != null) body['imgUrl'] = imgUrl;

      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode(body),
      );

      print('Update user response: ${response.statusCode}');
      print('Update user body: ${response.body}');

      if (response.statusCode == 204) {
        // 204 No Content - actualización exitosa
        return true;
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado para actualizar');
        return false;
      } else {
        print('Error al actualizar usuario: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al actualizar usuario: $e');
      return false;
    }
  }

  /// Actualizar ubicación del usuario (solo para OWNER)
  /// Endpoint: PUT /users/{id}/location
  Future<bool> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/users/$userId/location');

      final body = {
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode(body),
      );

      print('Update location response: ${response.statusCode}');
      print('Update location body: ${response.body}');

      if (response.statusCode == 204) {
        // 204 No Content - actualización exitosa
        return true;
      } else if (response.statusCode == 404) {
        print('Usuario no encontrado para actualizar ubicación');
        return false;
      } else if (response.statusCode == 403) {
        print('No tiene permisos para actualizar la ubicación (requiere rol OWNER)');
        return false;
      } else {
        print('Error al actualizar ubicación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error al actualizar ubicación: $e');
      return false;
    }
  }

  /// Limpiar el token de autenticación
  void clearAuthToken() {
    _token = null;
  }
}