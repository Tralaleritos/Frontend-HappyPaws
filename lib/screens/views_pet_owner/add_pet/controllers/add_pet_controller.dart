// controllers/add_pet_controller.dart
import 'package:flutter/material.dart';
import 'package:happyp/data/models/pet.dart';
import 'package:happyp/data/models/create_pet_request.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';

class AddPetController extends ChangeNotifier {
  final PetService _petService = PetService();
  final AuthService _authService;

  // Controladores de texto
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  // Estados
  bool _isLoading = false;
  Species _selectedSpecies = Species.DOG;
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  Species get selectedSpecies => _selectedSpecies;
  String? get errorMessage => _errorMessage;

  // Constructor que recibe el token de autenticación
  AddPetController(this._authService) {
    _initializeController();
  }
  // Método de inicialización asíncrono
  Future<void> _initializeController() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _petService.setAuthToken(token);

      } else {
        print("No hay token de autenticación disponible");
      }
    } catch (e) {
      print("Error inicializando HomeController: $e");
    }
  }

  // Lista de razas por especie
  final Map<Species, List<String>> _breedsBySpecies = {
    Species.DOG: [
      'Labrador',
      'Golden Retriever',
      'Bulldog',
      'Pastor Alemán',
      'Poodle',
      'Chihuahua',
      'Beagle',
      'Rottweiler',
      'Yorkshire Terrier',
      'Otro'
    ],
    Species.CAT: [
      'Persa',
      'Siamés',
      'Maine Coon',
      'Ragdoll',
      'British Shorthair',
      'Bengalí',
      'Abisinio',
      'Ruso Azul',
      'Sphynx',
      'Otro'
    ],
  };

  List<String> get availableBreeds => _breedsBySpecies[_selectedSpecies] ?? [];

  void setSpecies(Species species) {
    _selectedSpecies = species;
    breedController.clear(); // Limpiar raza cuando cambia la especie
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _errorMessage = 'El nombre es obligatorio';
      notifyListeners();
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      _errorMessage = 'La descripción es obligatoria';
      notifyListeners();
      return false;
    }

    if (breedController.text.trim().isEmpty) {
      _errorMessage = 'La raza es obligatoria';
      notifyListeners();
      return false;
    }

    final age = int.tryParse(ageController.text);
    if (age == null || age <= 0 || age > 30) {
      _errorMessage = 'La edad debe ser un número válido entre 1 y 30';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> createPet(int ownerId) async {
    if (!_validateForm()) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final petRequest = CreatePetRequest(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        species: _selectedSpecies.value,
        breed: breedController.text.trim(),
        age: int.parse(ageController.text),
        ownerId: ownerId,
        imgUrl: null,
      );

      await _petService.createPet(petRequest);

      _isLoading = false;
      notifyListeners();
      return true;

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al crear la mascota: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void resetForm() {
    nameController.clear();
    descriptionController.clear();
    breedController.clear();
    ageController.clear();
    _selectedSpecies = Species.DOG;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    breedController.dispose();
    ageController.dispose();
    super.dispose();
  }
}