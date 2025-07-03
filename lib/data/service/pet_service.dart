import 'dart:convert';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:http/http.dart' as http;
import '../models/pet/create_pet_request.dart';
import '../models/pet/update_pet_request.dart'; // Asegúrate de tener este modelo también

class PetService {
  final String _baseUrl = ApiConstants.BASE_URL; // 👈 Usar constante
  String? _token;

  // Establece el token de autenticación
  void setAuthToken(String token) {
    _token = token;
  }

  // Encabezados comunes para las solicitudes HTTP
  Map<String, String> get _headers {
    final baseHeaders = {'Content-Type': 'application/json'};
    if (_token != null) {
      baseHeaders['Authorization'] = 'Bearer $_token';
    }
    return baseHeaders;
  }

  // Obtener todas las mascotas del usuario autenticado
  Future<List<Pet>> getUserPets() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pets/my'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Pet.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load pets: ${response.body}');
    }
  }

  // Obtener una mascota por ID
  Future<Pet> getPetById(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pets/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Pet.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load pet: ${response.body}');
    }
  }

  // Crear una nueva mascota
  Future<Pet> createPet(CreatePetRequest petRequest) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/pets'),
      headers: _headers,
      body: json.encode(petRequest.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Pet.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create pet: ${response.body}');
    }
  }

  // Actualizar una mascota existente
  Future<void> updatePet(UpdatePetRequest updateRequest) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/pets/${updateRequest.id}'),
      headers: _headers,
      body: json.encode(updateRequest.toJson()),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to update pet: ${response.body}');
    }
  }

  // Eliminar una mascota
  Future<bool> deletePet(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/pets/$id'),
      headers: _headers,
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw Exception('Failed to delete pet: ${response.body}');
    }
  }
}