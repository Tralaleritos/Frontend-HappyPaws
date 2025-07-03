import 'package:flutter/material.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:happyp/screens/views_pet_owner/search/service_request_screen.dart';

import 'package:happyp/screens/views_pet_owner/home/widgets/pet_detail_screen.dart';


import 'package:provider/provider.dart';

class PetSearchController extends ChangeNotifier {
  // Servicios
  late final PetService _petService;
  late final AuthService _authService;

  // Estado de búsqueda y filtros
  String _searchQuery = '';
  String _selectedService = '';
  List<Pet> _allPets = [];
  List<Pet> _filteredPets = [];
  bool _isSearching = false;
  bool _isLoading = false;

  // Getters
  String get searchQuery => _searchQuery;
  String get selectedService => _selectedService;
  List<Pet> get allPets => _allPets;
  List<Pet> get filteredPets => _filteredPets;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;

  // Constructor
  PetSearchController(BuildContext context) {
    _petService = PetService();
    _authService = Provider.of<AuthService>(context, listen: false);
  }

  // Inicialización
  Future<void> initializeService() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _petService.setAuthToken(token);
        await loadAllPets();
      } else {
        debugPrint('[PetSearchController] No hay token disponible');
      }
    } catch (e) {
      debugPrint('[PetSearchController] Error inicializando servicio: $e');
    }
  }

  // Cargar todas las mascotas
  Future<void> loadAllPets() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pets = await _petService.getUserPets();
      _allPets = pets;
      _filteredPets = pets;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('[PetSearchController] Error cargando mascotas: $e');
      throw e; // Re-lanzar para que la UI pueda manejar el error
    }
  }

  // Actualizar búsqueda
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _isSearching = query.isNotEmpty;
    _filterPets();
    notifyListeners();
  }

  // Actualizar servicio seleccionado
  void updateSelectedService(String service) {
    _selectedService = _selectedService == service ? '' : service;
    _filterPets();
    notifyListeners();
  }

  // Limpiar filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedService = '';
    _isSearching = false;
    _filterPets();
    notifyListeners();
  }

  void _filterPets() {
    _filteredPets = _allPets.where((pet) {
      final searchLower = _searchQuery.toLowerCase();
      final matchesQuery = pet.name.toLowerCase().contains(searchLower) ||
          (pet.owner?.username.toLowerCase().contains(searchLower) ?? false);

      final matchesService = _selectedService.isEmpty;

      return matchesQuery && matchesService;
    }).toList();
  }

  // Método para navegar a solicitar servicio - CORREGIDO
  void navigateToAddService(BuildContext context, String service) {
    final user = _authService.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceRequestScreen(
            serviceType: service,
          ),
        ),
      ).then((_) => loadAllPets()); // Recargar las mascotas al volver
    } else {
      _showLoginDialog(context);
    }
  }

  // Mostrar diálogo de login - CORREGIDO el nombre del método
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar sesión requerido'),
        content: const Text('Debes iniciar sesión para realizar esta acción.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí puedes navegar a la pantalla de inicio de sesión
              // Navigator.pushNamed(context, '/login');
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  // Método público para mostrar el diálogo de login desde fuera
  void showLoginDialog(BuildContext context) {
    _showLoginDialog(context);
  }

  // Navegar a detalle de mascota
  void navigateToPetDetail(BuildContext context, Pet pet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(
          pet: pet,
          petService: _petService,
        ),
      ),
    );

    // Si result == true, significa que hubo cambios
    if (result == true) {
      await loadAllPets();
    }
  }


  @override
  void dispose() {
    // Limpiar recursos si es necesario
    super.dispose();
  }
}