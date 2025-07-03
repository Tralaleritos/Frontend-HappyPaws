// home_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../data/models/notifications/caregiver_nearby_response.dart';
import '../../../../data/service/notification_service.dart';

class HomeController with ChangeNotifier {
  // Servicios
  final PetService _petService = PetService();
  final AuthService _authService;
  // Servicio de notificaciones
  final NotificationService _notificationService = NotificationService();

  // Controlador para el mapa (mantenido para compatibilidad)
  final Completer<GoogleMapController> mapController = Completer();
  bool isSearching = false;
  bool showServiceForm = false;
  bool isLoadingPets = false;

  // Selección actual
  dynamic selectedCaregiverNearby; // CaregiversNearbyResponse

  // Información de la mascota - Integración con backend
  List<Pet> userPets = [];
  Pet? selectedPet;
  String selectedServiceType = 'Paseo';
  DateTime serviceDate = DateTime.now();
  TimeOfDay serviceTime = TimeOfDay.now();
  int serviceDuration = 60; // minutos
  double servicePrice = 35.00;

  // ID del dueño actual
  String? ownerId;

  // Posición inicial del mapa (mantenido para compatibilidad)
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(37.42200, -122.08400), // Lima, Perú por defecto
    zoom: 14.0,
  );

  // Marcadores para el mapa (mantenidos para compatibilidad)
  final Set<Marker> markers = {};
  final Set<Circle> circles = {};
  final Set<Marker> _caregiverMarkers = {};
  Set<Marker> get allMarkers => {...markers, ..._caregiverMarkers};

  HomeController(this._authService) {
    _initializeController();
    requestLocationPermission();
    _setupNotificationListener();
  }

  // Método de inicialización asíncrono
  Future<void> _initializeController() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _petService.setAuthToken(token);

        final user = _authService.currentUser;
        if (user != null && user.id.isNotEmpty) {
          ownerId = user.id;
          debugPrint('[HomeController] Owner ID asignado: $ownerId');

          // Inicializar el NotificationService después de obtener el ownerId
          await _initializeNotificationService(token, user.id);
        } else {
          debugPrint('[HomeController] currentUser o id es null');
        }

        await loadUserPets();
      } else {
        print("No hay token de autenticación disponible");
      }
    } catch (e) {
      print("Error inicializando HomeController: $e");
    }
  }

  void _setupNotificationListener() {
    _notificationService.addListener(_onCaregiverNotificationUpdate);
  }

  void _onCaregiverNotificationUpdate() {
    _updateCaregiverMarkers();
    notifyListeners(); // Notificar cambios para actualizar la UI
  }

  // Método para actualizar los marcadores de cuidadores en el mapa (mantenido para compatibilidad)
  void _updateCaregiverMarkers() {
    _caregiverMarkers.clear();

    final nearbyCaregivers = _notificationService.nearbyCaregivers;
    debugPrint('[HomeController] Actualizando marcadores: ${nearbyCaregivers.length} cuidadores cercanos');

    for (final caregiver in nearbyCaregivers) {
      final marker = Marker(
        markerId: MarkerId('caregiver_${caregiver.id}'),
        position: LatLng(caregiver.latitude, caregiver.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: caregiver.userName,
          snippet: 'Cuidador disponible',
          onTap: () => _onCaregiverMarkerTapped(caregiver),
        ),
      );
      _caregiverMarkers.add(marker);
    }
    debugPrint('[HomeController] Marcadores actualizados: ${_caregiverMarkers.length} marcadores en el mapa');
  }

  // Método para manejar cuando se toca un marcador de cuidador
  void _onCaregiverMarkerTapped(CaregiversNearbyResponse caregiver) {
    selectCaregiver(caregiver);
  }

  // Nuevo método para seleccionar un cuidador desde las cards
  void selectCaregiver(dynamic caregiver) {
    selectedCaregiverNearby = caregiver;
    debugPrint('Cuidador seleccionado: ${caregiver.userName}');

    // Aquí puedes agregar lógica adicional como:
    // - Mostrar un bottom sheet con detalles del cuidador
    // - Navegar a una pantalla de detalles
    // - Abrir un modal de reserva

    notifyListeners();
  }

  // Getter para obtener la lista de cuidadores cercanos
  List<CaregiversNearbyResponse> get nearbyCaregivers =>
      _notificationService.nearbyCaregivers;

  void clearNearbyCaregivers() {
    _notificationService.clearNearbyCaregivers();
    _caregiverMarkers.clear();
    selectedCaregiverNearby = null;
    notifyListeners();
  }

  // Cargar las mascotas del usuario desde el backend
  Future<void> loadUserPets() async {
    isLoadingPets = true;
    notifyListeners();

    try {
      userPets = await _petService.getUserPets();
      if (userPets.isNotEmpty) {
        selectedPet = userPets.first;
      }
    } catch (e) {
      print("Error cargando las mascotas del usuario: $e");
    } finally {
      isLoadingPets = false;
      notifyListeners();
    }
  }

  PetService get petService => _petService;

  // Solicitar permisos de ubicación
  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      getCurrentLocation();
    }
  }

  // Obtener la ubicación actual
  Future<void> getCurrentLocation() async {
    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        // Simular actualización de ubicación para buscar cuidadores cercanos
        // En una implementación real, aquí obtendrías la ubicación GPS real
        debugPrint('[HomeController] Actualizando ubicación y buscando cuidadores cercanos...');

        // Aquí podrías llamar a un método para buscar cuidadores en la nueva ubicación
        // await _searchCaregiversInLocation(newLatitude, newLongitude);

        notifyListeners();
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Método para inicializar el NotificationService
  Future<void> _initializeNotificationService(String authToken, String userId) async {
    try {
      _notificationService.initialize(
        authToken: authToken,
        userId: userId,
        caregiverId: int.parse(userId),
        serverUrl: ApiConstants.BASE_URL,
      );

      debugPrint('[HomeController] NotificationService inicializado correctamente');
    } catch (e) {
      print('Error al inicializar servicio de notificaciones: $e');
    }
  }

  // Cambiar tipo de servicio
  void changeServiceType(String type) {
    selectedServiceType = type;
    notifyListeners();
  }

  // Seleccionar mascota
  void selectPet(Pet pet) {
    selectedPet = pet;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onCaregiverNotificationUpdate);
    super.dispose();
  }
}