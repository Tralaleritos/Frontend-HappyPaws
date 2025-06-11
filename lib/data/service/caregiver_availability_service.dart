import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:happyp/data/models/caregiver_availability.dart';

class CaregiverAvailabilityService {
  static const String _baseUrl = 'http://10.0.2.2:5000/api/v1';
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // Crear disponibilidad inicial del cuidador
  Future<int> createCaregiverAvailability({
    required int caregiverId,
    required String locationName,
    required double locationLatitude,
    required double locationLongitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/caregivers-availability'),
        headers: _headers,
        body: jsonEncode({
          'caregiverId': caregiverId,
          'locationName': locationName,
          'locationLatitude': locationLatitude,
          'locationLongitude': locationLongitude,
        }),
      );

      print('CREATE - Status Code: ${response.statusCode}');
      print('CREATE - Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return int.parse(response.body);
      } else {
        throw Exception('Error al crear disponibilidad: ${response.body}');
      }
    } catch (e) {
      print('CREATE - Error: $e');
      throw Exception('Error de conexión al crear disponibilidad: $e');
    }
  }

  // Poner cuidador como disponible
  Future<void> setCaregiverAvailable({
    required int caregiverId,
    required String locationName,
    required double locationLatitude,
    required double locationLongitude,
  }) async {
    try {
      // CORRECCIÓN: Eliminar el slash extra entre caregivers-availability y caregiver
      final url = '$_baseUrl/caregivers-availability/caregiver/$caregiverId/available';

      print('AVAILABLE - URL: $url');
      print('AVAILABLE - Headers: $_headers');
      print('AVAILABLE - Body: ${jsonEncode({
        'locationName': locationName,
        'locationLatitude': locationLatitude,
        'locationLongitude': locationLongitude,
      })}');

      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'locationName': locationName,
          'locationLatitude': locationLatitude,
          'locationLongitude': locationLongitude,
        }),
      );

      print('AVAILABLE - Status Code: ${response.statusCode}');
      print('AVAILABLE - Response Body: ${response.body}');

      if (response.statusCode != 204) {
        throw Exception('Error al activar disponibilidad: ${response.body}');
      }
    } catch (e) {
      print('AVAILABLE - Error: $e');
      throw Exception('Error de conexión al activar disponibilidad: $e');
    }
  }

  // Poner cuidador como no disponible
  Future<void> setCaregiverUnavailable({
    required int caregiverId,
  }) async {
    try {
      // CORRECCIÓN: Eliminar el slash extra entre caregivers-availability y caregiver
      final url = '$_baseUrl/caregivers-availability/caregiver/$caregiverId/unavailable';

      print('UNAVAILABLE - URL: $url');
      print('UNAVAILABLE - Headers: $_headers');

      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
      );

      print('UNAVAILABLE - Status Code: ${response.statusCode}');
      print('UNAVAILABLE - Response Body: ${response.body}');

      if (response.statusCode != 204) {
        throw Exception('Error al desactivar disponibilidad: ${response.body}');
      }
    } catch (e) {
      print('UNAVAILABLE - Error: $e');
      throw Exception('Error de conexión al desactivar disponibilidad: $e');
    }
  }
}