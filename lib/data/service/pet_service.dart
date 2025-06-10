// services/pet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet.dart';
import '../models/create_pet_request.dart';

class PetService {
  final String _baseUrl = 'http://10.0.2.2:5000/api/v1/auth';
  String? _token;


  // Método para establecer el token de autenticación
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


  // Obtener todas las mascotas del usuario
  Future<List<Pet>> getUserPets() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/pets/my'), // <- Ruta correcta
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
  Future<Pet> getPetById(String id) async {
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

    if (response.statusCode == 200) {
      return Pet.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create pet: ${response.body}');
    }
  }

  // Actualizar una mascota existente


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