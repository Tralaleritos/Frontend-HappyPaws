/*import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../core/constants/ApiConstants.dart';
import '../models/nueva/user_model.dart';

class AuthService {
  static const String _baseUrl = ApiConstants.BASE_URL;

  // Método para registrar un nuevo usuario
  Future<ApiResponse<String>> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(user.toJson()),
      );

      final responseData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200 || response.statusCode == 201,
        message: responseData['message'] ?? 'Error en el registro',
        data: responseData['data'] != null ? responseData['data']['email'] : null,
      );
    } catch (e) {
      debugPrint('Error en el registro: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión. Verifica tu internet e intenta nuevamente.',
      );
    }
  }

  // Método para verificar el código enviado por email
  Future<ApiResponse<bool>> verifyEmailCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final responseData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200,
        message: responseData['message'] ?? 'Error al verificar el código',
        data: response.statusCode == 200,
      );
    } catch (e) {
      debugPrint('Error al verificar el código: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión. Verifica tu internet e intenta nuevamente.',
      );
    }
  }

  // Método para solicitar un nuevo código de verificación
  Future<ApiResponse<bool>> resendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/resend-code'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final responseData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200,
        message: responseData['message'] ?? 'Error al reenviar el código',
        data: response.statusCode == 200,
      );
    } catch (e) {
      debugPrint('Error al reenviar el código: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión. Verifica tu internet e intenta nuevamente.',
      );
    }
  }

  // Método para actualizar la contraseña (cuando se olvidó)
  Future<ApiResponse<bool>> updatePassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/update-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      return ApiResponse(
        success: response.statusCode == 200,
        message: responseData['message'] ?? 'Error al actualizar la contraseña',
        data: response.statusCode == 200,
      );
    } catch (e) {
      debugPrint('Error al actualizar la contraseña: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión. Verifica tu internet e intenta nuevamente.',
      );
    }
  }

  // Método para iniciar sesión
  Future<ApiResponse<User>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['data'] != null) {
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Inicio de sesión exitoso',
          data: User.fromJson(responseData['data']),
        );
      } else {
        return ApiResponse(
          success: false,
          message: responseData['message'] ?? 'Credenciales incorrectas',
        );
      }
    } catch (e) {
      debugPrint('Error en el inicio de sesión: $e');
      return ApiResponse(
        success: false,
        message: 'Error de conexión. Verifica tu internet e intenta nuevamente.',
      );
    }
  }
}*/