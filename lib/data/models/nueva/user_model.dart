import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  String? id;
  String names;
  String lastname;
  String email;
  String phone;
  String password;
  String? repeatPassword; // Opcional en respuestas del servidor
  bool terms;
  String photoUrl;
  String role; // 'owner' o 'caretaker'

  // Getters para facilitar el acceso a información útil
  String get fullName => '$names $lastname';
  bool get isOwner => role == 'owner';
  bool get isCaretaker => role == 'caretaker';

  User({
    this.id,
    required this.names,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.password,
    this.repeatPassword,
    required this.terms,
    required this.photoUrl,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      names: json['names'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      repeatPassword: json['repeatPassword'], // Puede ser null
      terms: json['terms'] is String
          ? json['terms'].toLowerCase() == 'true'
          : json['terms'] ?? false,
      photoUrl: json['photoUrl'] ?? '',
      role: json['role'] ?? 'owner', // Por defecto es owner si no se especifica
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'names': names,
      'lastname': lastname,
      'email': email,
      'phone': phone,
      'password': password,
      'terms': terms,
      'photoUrl': photoUrl,
      'role': role,
    };

    // Solo incluir el ID si existe
    if (id != null) {
      data['id'] = id;
    }

    // Solo incluir repeatPassword si existe
    if (repeatPassword != null) {
      data['repeatPassword'] = repeatPassword;
    }

    return data;
  }
}
//pet_model.dart
class Pet {
  String? id;
  String name;
  String type;
  String breed;
  int age;
  double weight;
  String gender;
  bool vaccinated;
  List<String> photoUrls;
  String description;
  String service;
  double priceService;
  String userId;

  Pet({
    this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.weight,
    required this.gender,
    required this.vaccinated,
    required this.photoUrls,
    required this.description,
    required this.service,
    required this.priceService,
    required this.userId,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] is String
          ? int.tryParse(json['age']) ?? 0
          : json['age'] ?? 0,
      weight: json['weight'] is String
          ? double.tryParse(json['weight']) ?? 0.0
          : (json['weight'] ?? 0).toDouble(),
      gender: json['gender'] ?? '',
      vaccinated: json['vaccinated'] is String
          ? json['vaccinated'].toLowerCase() == 'true'
          : json['vaccinated'] ?? false,
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      description: json['description'] ?? '',
      service: json['service'] ?? '',
      priceService: json['priceService'] is String
          ? double.tryParse(json['priceService']) ?? 0.0
          : (json['priceService'] ?? 0).toDouble(),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'weight': weight,
      'gender': gender,
      'vaccinated': vaccinated,
      'photoUrls': photoUrls,
      'description': description,
      'service': service,
      'priceService': priceService,
      'userId': userId,
    };
  }

  @override
  String toString() {
    return 'Pet(id: $id, name: $name, type: $type, breed: $breed, photos: $photoUrls, owner: $userId)';
  }
}

// ------------------ SERVICIOS ------------------
// api_service.dart
class ApiService {
  final String baseUrl = 'https://67474cf238c8741641d63e57.mockapi.io/api/v1';

  Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }

  Future<http.Response> getById(String endpoint, String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }

  Future<http.Response> post(String endpoint, dynamic data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return response;
  }

  Future<http.Response> put(String endpoint, String id, dynamic data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return response;
  }

  Future<http.Response> delete(String endpoint, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }

  Future<http.Response> getWithQuery(String endpoint, Map<String, String> queryParams) async {
    final Uri uri = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    return response;
  }
}
// lib/services/user_service.dart
class UserService {
  final ApiService _apiService = ApiService();
  final String endpoint = 'users';

  // Obtener todos los usuarios
  Future<List<User>> getAllUsers() async {
    try {
      final http.Response response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => User.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Obtener un usuario por ID
  Future<User> getUserById(String id) async {
    try {
      final http.Response response = await _apiService.getById(endpoint, id);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Error al obtener usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Crear un usuario
  Future<User> createUser(User user) async {
    try {
      final http.Response response = await _apiService.post(endpoint, user.toJson());

      if (response.statusCode == 201) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Error al crear usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Actualizar un usuario
  Future<User> updateUser(User user) async {
    try {
      if (user.id == null) {
        throw Exception('El ID del usuario no puede ser nulo');
      }

      final http.Response response = await _apiService.put(endpoint, user.id!, user.toJson());

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Error al actualizar usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Eliminar un usuario
  Future<bool> deleteUser(String id) async {
    try {
      final http.Response response = await _apiService.delete(endpoint, id);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Iniciar sesión (validación simple por email y contraseña)
  // Verificar las credenciales de login (email y contraseña)
  Future<User?> login(String email, String password) async {
    try {
      // Crear los parámetros para la consulta
      Map<String, String> queryParams = {'email': email, 'password': password};
      final http.Response response = await _apiService.getWithQuery(endpoint, queryParams);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return User.fromJson(data[0]);
        } else {
          return null; // No se encontró usuario con esas credenciales
        }
      } else {
        throw Exception('Error al autenticar usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }
}
//pet_service.dart
class PetService {
  final ApiService _apiService = ApiService();
  final String endpoint = 'pets';

  // Obtener todas las mascotas
  Future<List<Pet>> getAllPets() async {
    try {
      final http.Response response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Pet.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener mascotas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Obtener una mascota por ID
  Future<Pet> getPetById(String id) async {
    try {
      final http.Response response = await _apiService.getById(endpoint, id);

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Pet.fromJson(data);
      } else {
        throw Exception('Error al obtener mascota: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Obtener mascotas por ID de usuario
  Future<List<Pet>> getPetsByUserId(String userId) async {
    try {
      final http.Response response = await _apiService.getWithQuery(
          endpoint,
          {'userId': userId}
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Pet.fromJson(item)).toList();
      } else {
        throw Exception('Error al obtener mascotas del usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Crear una mascota
  Future<Pet> createPet(Pet pet) async {
    try {
      final http.Response response = await _apiService.post(endpoint, pet.toJson());

      if (response.statusCode == 201) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Pet.fromJson(data);
      } else {
        throw Exception('Error al crear mascota: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Actualizar una mascota
  Future<Pet> updatePet(Pet pet) async {
    try {
      if (pet.id == null) {
        throw Exception('El ID de la mascota no puede ser nulo');
      }

      final http.Response response = await _apiService.put(endpoint, pet.id!, pet.toJson());

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return Pet.fromJson(data);
      } else {
        throw Exception('Error al actualizar mascota: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }

  // Eliminar una mascota
  Future<bool> deletePet(String id) async {
    try {
      final http.Response response = await _apiService.delete(endpoint, id);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error en la solicitud: $e');
    }
  }
}
// ------------------ PROVIDERS ------------------
// auth_provider.dart
class AuthProvider with ChangeNotifier {
  final UserService _userService = UserService();

  User? _currentUser;
  bool _isLoading = false;
  String _error = '';

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String get error => _error;

  // Iniciar sesión
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final user = await _userService.login(email, password);

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales inválidas';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Registrar un nuevo usuario
  Future<bool> register(User user) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final createdUser = await _userService.createUser(user);
      _currentUser = createdUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar datos del usuario
  Future<bool> updateUserProfile(User user) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final updatedUser = await _userService.updateUser(user);
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
//pet_provider.dart
class PetProvider with ChangeNotifier {
  final PetService _petService = PetService();

  List<Pet> _pets = [];
  bool _isLoading = false;
  String _error = '';

  List<Pet> get pets => _pets;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Cargar mascotas de un usuario específico
  Future<void> loadUserPets(String userId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _pets = await _petService.getPetsByUserId(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar una nueva mascota
  Future<bool> addPet(Pet pet) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final createdPet = await _petService.createPet(pet);
      _pets.add(createdPet);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar una mascota existente
  Future<bool> updatePet(Pet pet) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final updatedPet = await _petService.updatePet(pet);

      final index = _pets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        _pets[index] = updatedPet;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar una mascota
  Future<bool> deletePet(String id) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final result = await _petService.deletePet(id);

      if (result) {
        _pets.removeWhere((pet) => pet.id == id);
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

