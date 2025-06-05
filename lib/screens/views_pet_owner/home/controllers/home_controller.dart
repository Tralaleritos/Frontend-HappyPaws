// home_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:happyp/data/models/pet.dart';
import 'package:happyp/data/models/pet_caregiver.dart';

class HomeController with ChangeNotifier {
  // Servicios
  final PetService _petService = PetService();
  final AuthService _authService;

  // Controlador para el mapa
  final Completer<GoogleMapController> mapController = Completer();
  bool isSearching = false;
  bool showCaregiverDetails = false;
  bool showServiceForm = false;
  bool isLoadingPets = false;

  // Estado para los cuidadores visibles y favoritos
  List<PetCaregiver> visibleCaregivers = [];
  final List<PetCaregiver> favoriteCaregivers = [];

  // Selección actual
  PetCaregiver? selectedCaregiver;

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


  // Posición inicial del mapa
  static const CameraPosition initialCameraPosition = CameraPosition(
    target: LatLng(-12.0464, -77.0428), // Lima, Perú por defecto
    zoom: 14.0,
  );

  // Marcadores para el mapa
  final Set<Marker> markers = {};
  final Set<Circle> circles = {};

  // Datos simulados para los cuidadores (mantenidos tal como estaban)
  final List<PetCaregiver> mockCaregivers = [
    PetCaregiver(
      id: '1',
      name: 'María López',
      rating: 4.8,
      specialties: ['Perros', 'Gatos', 'Paseos'],
      price: 35.00,
      distance: 1.2,
      location: const LatLng(-12.0864, -77.0442),
      description:
      'Amante de los animales con 5 años de experiencia cuidando mascotas.',
      reviews: 124,
      isOnline: true,
    ),
    PetCaregiver(
      id: '2',
      name: 'Juan Martínez',
      rating: 4.6,
      specialties: ['Perros grandes', 'Entrenamiento', 'Paseos'],
      price: 40.00,
      distance: 2.5,
      location: const LatLng(-12.0951, -77.0535),
      description:
      'Entrenador profesional de perros con certificación en primeros auxilios para mascotas.',
      reviews: 89,
      isOnline: true,
    ),
    PetCaregiver(
      id: '3',
      name: 'Ana García',
      rating: 4.9,
      specialties: ['Gatos', 'Medicina', 'Cuidado a domicilio'],
      price: 45.00,
      distance: 3.1,
      location: const LatLng(-12.0751, -77.0382),
      description:
      'Veterinaria con amplia experiencia en cuidado de mascotas a domicilio.',
      reviews: 156,
      isOnline: false,
    ),
  ];

  HomeController(this._authService) {
    _initializeController();
    visibleCaregivers = mockCaregivers;
    requestLocationPermission();
    addMockMarkers();
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
        final GoogleMapController controller = await mapController.future;

        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(
              target: LatLng(-12.0464, -77.0428),
              zoom: 14.0,
            ),
          ),
        );

        circles.clear();
        circles.add(
          Circle(
            circleId: const CircleId('searchArea'),
            center: const LatLng(-12.0464, -77.0428),
            radius: 2000,
            fillColor: Colors.blue.withOpacity(0.1),
            strokeColor: Colors.blue.withOpacity(0.5),
            strokeWidth: 2,
          ),
        );
        notifyListeners();
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  // Añadir marcadores para los cuidadores mock
  void addMockMarkers() {
    markers.clear();
    for (var caregiver in mockCaregivers) {
      markers.add(
        Marker(
          markerId: MarkerId(caregiver.id),
          position: caregiver.location,
          infoWindow: InfoWindow(
            title: caregiver.name,
            snippet: '${caregiver.rating} ★ - ${caregiver.distance} km',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            caregiver.isOnline
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          onTap: () {
            selectCaregiver(caregiver);
          },
        ),
      );
    }
    notifyListeners();
  }

  // Seleccionar un cuidador
  void selectCaregiver(PetCaregiver caregiver) {
    selectedCaregiver = caregiver;
    showCaregiverDetails = true;
    notifyListeners();

    mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: caregiver.location,
            zoom: 15.0,
          ),
        ),
      );
    });
  }

  // Iniciar búsqueda de cuidadores
  void startSearch() {
    isSearching = true;
    selectedCaregiver = null;
    showCaregiverDetails = false;
    markers.clear();
    notifyListeners();

    // Simular búsqueda durante 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      isSearching = false;
      showCaregiversAnimated();
    });
  }

  // Mostrar cuidadores animados
  void showCaregiversAnimated() {
    List<PetCaregiver> filteredCaregivers = mockCaregivers.where((caregiver) {
      if (selectedServiceType == 'Paseo') {
        return caregiver.specialties.contains('Paseos');
      } else if (selectedServiceType == 'Visita a domicilio') {
        return caregiver.specialties.contains('Cuidado a domicilio');
      } else if (selectedServiceType == 'Entrenamiento') {
        return caregiver.specialties.contains('Entrenamiento');
      }
      return true;
    }).toList();

    visibleCaregivers = filteredCaregivers;
    notifyListeners();

    for (int i = 0; i < filteredCaregivers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 * i), () {
        addCaregiverMarker(filteredCaregivers[i]);
      });
    }

    updateMapViewForResults(filteredCaregivers);
  }

  // Añadir marcador de cuidador
  void addCaregiverMarker(PetCaregiver caregiver) {
    markers.add(
      Marker(
        markerId: MarkerId(caregiver.id),
        position: caregiver.location,
        infoWindow: InfoWindow(
          title: caregiver.name,
          snippet: '${caregiver.rating} ★ - ${caregiver.distance} km',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          caregiver.isOnline
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueOrange,
        ),
        onTap: () {
          selectCaregiver(caregiver);
        },
      ),
    );
    notifyListeners();
  }

  // Actualizar la vista del mapa para los resultados
  void updateMapViewForResults(List<PetCaregiver> caregivers) {
    if (caregivers.isEmpty) return;

    mapController.future.then((controller) {
      if (caregivers.length == 1) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: caregivers.first.location,
              zoom: 15.0,
            ),
          ),
        );
      } else {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(
              target: LatLng(-12.0464, -77.0428),
              zoom: 13.0,
            ),
          ),
        );
      }
    });
  }

  // Enviar solicitud de servicio
  void sendServiceRequest() {
    showServiceForm = false;
    notifyListeners();
  }

  // Mostrar formulario de solicitud de servicio
  void showServiceRequestForm() {
    showCaregiverDetails = false;
    showServiceForm = true;
    notifyListeners();
  }

  // Cerrar detalles de cuidador
  void closeDetails() {
    showCaregiverDetails = false;
    notifyListeners();
  }

  // Manejo de favoritos
  void toggleFavorite(PetCaregiver caregiver) {
    if (favoriteCaregivers.contains(caregiver)) {
      favoriteCaregivers.remove(caregiver);
    } else {
      favoriteCaregivers.add(caregiver);
    }
    notifyListeners();
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

  // Actualizar fecha de servicio
  void updateServiceDate(DateTime date) {
    serviceDate = date;
    notifyListeners();
  }

  // Actualizar hora de servicio
  void updateServiceTime(TimeOfDay time) {
    serviceTime = time;
    notifyListeners();
  }

  // Actualizar duración de servicio
  void updateServiceDuration(int duration) {
    serviceDuration = duration;
    notifyListeners();
  }

  // Calcular precio total
  double calculateTotalPrice() {
    return (servicePrice * serviceDuration / 60);
  }

  // Actualizar precio según tipo de servicio
  void updateServicePrice(PetCaregiver caregiver, String serviceType) {
    if (serviceType == 'Paseo') {
      servicePrice = caregiver.price;
    } else if (serviceType == 'Visita a domicilio') {
      servicePrice = caregiver.price * 1.2;
    } else if (serviceType == 'Cuidado nocturno') {
      servicePrice = caregiver.price * 2;
    } else if (serviceType == 'Entrenamiento') {
      servicePrice = caregiver.price * 1.5;
    } else {
      servicePrice = caregiver.price * 1.8;
    }
    notifyListeners();
  }
}