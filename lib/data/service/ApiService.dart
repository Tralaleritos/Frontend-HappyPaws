
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet.dart';
import '../models/vet.dart';


class ApiService {
  static const String baseUrl = 'https://68219f26259dad2655afd976.mockapi.io/api/v1/pets';

  Future<List<Pet>> getPets() async {
    final response = await http.get(Uri.parse('$baseUrl/pets'));
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((e) => Pet.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar mascotas');
    }
  }

  Future<List<Vet>> getVets() async {
    final response = await http.get(Uri.parse('$baseUrl/vets'));
    if (response.statusCode == 200) {
      final List jsonData = json.decode(response.body);
      return jsonData.map((e) => Vet.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar veterinarios');
    }
  }
}

