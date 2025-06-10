import 'dart:convert';

import 'package:happyp/data/models/offer.dart';
import 'package:http/http.dart' as http;

class OfferService {
  final String _baseUrl = 'http://10.0.2.2:5000/api/v1'; // Ajusta si es necesario
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

  // Crear nueva oferta
  Future<OfferResponse> createOffer(CreateOfferRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/offers'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');


    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return OfferResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Error al crear oferta: ${response.body}');
    }
  }

  // Obtener oferta por ID
  Future<OfferResponse> getOfferById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/offers/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return OfferResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Oferta no encontrada: ${response.body}');
    }
  }

  // (Opcional) Obtener todas las ofertas del usuario logueado
  Future<List<OfferResponse>> getMyOffers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/offers/my'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse.map((data) => OfferResponse.fromJson(data)).toList();
    } else {
      throw Exception('Error al obtener ofertas: ${response.body}');
    }
  }
}