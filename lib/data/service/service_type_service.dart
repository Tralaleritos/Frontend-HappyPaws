import 'dart:convert';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/offers/offer.dart';
import 'package:http/http.dart' as http;

class ServiceTypeService {
  final String _baseUrl = ApiConstants.BASE_URL; // 👈 Usar constante
  String? _token;

  // Establecer el token
  void setAuthToken(String token) {
    _token = token;
  }

  // Headers con o sin token
  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Obtener todos los tipos de servicio disponibles
  Future<List<ServiceType>> getAllServiceTypes() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/services'), // Ajusta la URL según tu API
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => ServiceType.fromJson(data)).toList();
    } else {
      throw Exception('Error al obtener tipos de servicio: ${response.body}');
    }
  }

  // Obtener un tipo de servicio por ID
  Future<ServiceType> getServiceTypeById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/service/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return ServiceType.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Tipo de servicio no encontrado: ${response.body}');
    }
  }
}