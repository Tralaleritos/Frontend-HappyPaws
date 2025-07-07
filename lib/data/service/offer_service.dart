import 'dart:convert';

import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/offers/offer.dart';
import 'package:happyp/data/models/offers/accepted_offer_response.dart';
import 'package:http/http.dart' as http;

import '../models/offers/accept_offer.dart';
import '../models/offers/direct_offer.dart';

class OfferService {
  final String _baseUrl = ApiConstants.BASE_URL;
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

  // Obtener ofertas aceptadas del usuario (owner o caregiver)
  Future<List<AcceptedOfferResponse>> getAcceptedOffers(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/offers/accepted/$userId'),
      headers: _headers,
    );

    print('Get accepted offers - Status code: ${response.statusCode}');
    print('Get accepted offers - Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = jsonDecode(response.body);
      return jsonResponse
          .map((data) => AcceptedOfferResponse.fromJson(data))
          .toList();
    } else {
      throw Exception('Error al obtener ofertas aceptadas: ${response.body}');
    }
  }

  // Aceptar oferta (solo para cuidadores)
  Future<void> acceptOffer(AcceptOfferRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/offers/accept'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    print('Accept offer - Status code: ${response.statusCode}');
    print('Accept offer - Response body: ${response.body}');

    if (response.statusCode == 204) {
      // Éxito - No content
      return;
    } else {
      throw Exception('Error al aceptar oferta: ${response.body}');
    }
  }


  Future<void> completeOffer(int offerId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/offers/$offerId/complete'),
      headers: _headers,
    );

    print('Complete offer - Status code: ${response.statusCode}');
    print('Complete offer - Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Éxito
      return;
    } else {
      throw Exception('Error al completar oferta: ${response.body}');
    }
  }

  // Crear oferta directa a un cuidador específico
  Future<OfferResponse> createDirectOffer(DirectOfferRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/offers/direct-offer'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    print('Direct offer - Status code: ${response.statusCode}');
    print('Direct offer - Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return OfferResponse.fromJson(jsonResponse);
    } else {
      throw Exception('Error al crear oferta directa: ${response.body}');
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