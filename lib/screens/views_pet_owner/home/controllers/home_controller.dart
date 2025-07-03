// home_controller.dart - Versión Optimizada
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../data/models/notifications/caregiver_nearby_response.dart';
import '../../../../data/service/notification_service.dart';

class HomeController with ChangeNotifier {
  // Servicios
  final PetService _petService = PetService();
  final AuthService _authService;
  final NotificationService _notificationService = NotificationService();

  // Controlador para el mapa
  final Completer<GoogleMapController> mapController = Completer();
  bool isSearching = false;
  bool showServiceForm = false;
  bool isLoadingPets = false;
  bool isLoadingLocation = false;

  // Selección actual
  dynamic selectedCaregiverNearby;

  // Información de la mascota
  List<Pet> userPets = [];
  Pet? selectedPet;
  String selectedServiceType = 'Paseo';
  DateTime serviceDate = DateTime.now();
  TimeOfDay serviceTime = TimeOfDay.now();
  int serviceDuration = 60;
  double servicePrice = 35.00;

  // ID del dueño actual
  String? ownerId;

  // Posición actual del usuario
  Position? currentPosition;

  // Posición inicial del mapa (Lima, Perú)
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(-12.0464, -77.0428),
    zoom: 14.0,
  );

  // Marcadores para el mapa
  final Set<Marker> markers = {};
  final Set<Circle> circles = {};
  final Set<Marker> _caregiverMarkers = {};
  Set<Marker> get allMarkers => {...markers, ..._caregiverMarkers};

  // Marcadores personalizados
  BitmapDescriptor? caregiverIcon;
  BitmapDescriptor? selectedCaregiverIcon;

  // OPTIMIZACIÓN: Cache de marcadores para evitar recreación innecesaria
  final Map<int, Marker> _caregiverMarkersCache = {};

  // OPTIMIZACIÓN: Control de actualizaciones en batch
  Timer? _updateTimer;
  bool _pendingUpdate = false;

  // OPTIMIZACIÓN: Seguimiento de cambios
  Set<int> _lastCaregiverIds = {};

  HomeController(this._authService) {
    _initializeController();
    _loadCustomMarkers();
    requestLocationPermission();
    _setupNotificationListener();
  }

  // Cargar marcadores personalizados
  Future<void> _loadCustomMarkers() async {
    try {
      // OPTIMIZACIÓN: Cargar marcadores en paralelo
      final futures = await Future.wait([
        _createCustomMarker(Icons.pets, Colors.blue, Colors.white),
        _createCustomMarker(Icons.pets, Colors.orange, Colors.white),
      ]);

      caregiverIcon = futures[0];
      selectedCaregiverIcon = futures[1];

      // OPTIMIZACIÓN: Actualizar marcadores después de cargar iconos
      _scheduleMarkerUpdate();
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
      caregiverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      selectedCaregiverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  // Crear marcador personalizado
  Future<BitmapDescriptor> _createCustomMarker(
      IconData iconData,
      Color backgroundColor,
      Color iconColor,
      ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = backgroundColor;
    final double radius = 30;

    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 35,
        fontFamily: iconData.fontFamily,
        color: iconColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage(radius.toInt() * 2, radius.toInt() * 2);
    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final Uint8List uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  // Inicialización del controlador
  Future<void> _initializeController() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _petService.setAuthToken(token);

        final user = _authService.currentUser;
        if (user != null && user.id.isNotEmpty) {
          ownerId = user.id;
          debugPrint('[HomeController] Owner ID asignado: $ownerId');

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

  // OPTIMIZACIÓN: Programar actualización en batch para evitar múltiples actualizaciones
  void _onCaregiverNotificationUpdate() {
    debugPrint('[HomeController] Notificación de cambio de cuidador recibida');
    _scheduleMarkerUpdate();
  }

  // OPTIMIZACIÓN: Programar actualización con debounce
  void _scheduleMarkerUpdate() {
    if (_pendingUpdate) return;

    _pendingUpdate = true;
    _updateTimer?.cancel();

    _updateTimer = Timer(const Duration(milliseconds: 100), () {
      _pendingUpdate = false;
      _updateCaregiverMarkersOptimized();
      notifyListeners();
    });
  }

  // OPTIMIZACIÓN: Actualización inteligente de marcadores
  void _updateCaregiverMarkersOptimized() {
    final nearbyCaregivers = _notificationService.nearbyCaregivers;
    final currentCaregiverIds = nearbyCaregivers.map((c) => c.id).toSet();

    debugPrint('[HomeController] Actualizando marcadores: ${nearbyCaregivers.length} cuidadores');

    // Determinar qué marcadores necesitan actualizarse
    final toAdd = currentCaregiverIds.difference(_lastCaregiverIds);
    final toRemove = _lastCaregiverIds.difference(currentCaregiverIds);
    final toUpdate = currentCaregiverIds.intersection(_lastCaregiverIds);

    debugPrint('[HomeController] Marcadores - Agregar: ${toAdd.length}, Remover: ${toRemove.length}, Actualizar: ${toUpdate.length}');

    // Remover marcadores de cuidadores que ya no están disponibles
    for (final id in toRemove) {
      _caregiverMarkers.removeWhere((marker) => marker.markerId.value == 'caregiver_$id');
      _caregiverMarkersCache.remove(id);

      // Si el cuidador seleccionado fue removido, deseleccionarlo
      if (selectedCaregiverNearby?.id == id) {
        selectedCaregiverNearby = null;
        debugPrint('[HomeController] Cuidador seleccionado removido: $id');
      }
    }

    // Agregar o actualizar marcadores
    for (final caregiver in nearbyCaregivers) {
      final needsUpdate = toAdd.contains(caregiver.id) ||
          toUpdate.contains(caregiver.id) ||
          (selectedCaregiverNearby?.id == caregiver.id);

      if (needsUpdate) {
        _updateSingleCaregiverMarker(caregiver);
      }
    }

    _lastCaregiverIds = currentCaregiverIds;
    debugPrint('[HomeController] Marcadores actualizados: ${_caregiverMarkers.length} marcadores activos');
  }

  // OPTIMIZACIÓN: Actualizar un solo marcador
  void _updateSingleCaregiverMarker(CaregiversNearbyResponse caregiver) {
    final isSelected = selectedCaregiverNearby?.id == caregiver.id;

    final marker = Marker(
      markerId: MarkerId('caregiver_${caregiver.id}'),
      position: LatLng(caregiver.latitude, caregiver.longitude),
      icon: isSelected
          ? (selectedCaregiverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange))
          : (caregiverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)),
      infoWindow: InfoWindow(
        title: caregiver.userName,
        snippet: 'Cuidador disponible - Toca para más info',
      ),
      onTap: () => _onCaregiverMarkerTapped(caregiver),
    );

    // Remover el marcador anterior si existe
    _caregiverMarkers.removeWhere((m) => m.markerId.value == 'caregiver_${caregiver.id}');

    // Agregar el nuevo marcador
    _caregiverMarkers.add(marker);
    _caregiverMarkersCache[caregiver.id] = marker;

    debugPrint('[HomeController] Marcador actualizado para cuidador: ${caregiver.userName} (ID: ${caregiver.id})');
  }

  // Manejar toque en marcador de cuidador
  void _onCaregiverMarkerTapped(CaregiversNearbyResponse caregiver) {
    selectCaregiver(caregiver);
    _animateToCaregiver(caregiver);
  }

  // Animar cámara hacia el cuidador seleccionado
  Future<void> _animateToCaregiver(CaregiversNearbyResponse caregiver) async {
    if (mapController.isCompleted) {
      final controller = await mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(caregiver.latitude, caregiver.longitude),
          16.0,
        ),
      );
    }
  }

  // OPTIMIZACIÓN: Seleccionar cuidador sin recrear todos los marcadores
  void selectCaregiver(dynamic caregiver) {
    final previousSelected = selectedCaregiverNearby;
    selectedCaregiverNearby = caregiver;

    if (previousSelected?.id != caregiver?.id) {
      debugPrint('Cuidador seleccionado: ${caregiver?.userName ?? 'Ninguno'}');

      // Solo actualizar los marcadores afectados
      if (previousSelected != null) {
        _updateSingleCaregiverMarker(previousSelected);
      }
      if (caregiver != null) {
        _updateSingleCaregiverMarker(caregiver);
      }

      notifyListeners();
    }
  }

  // Obtener lista de cuidadores cercanos
  List<CaregiversNearbyResponse> get nearbyCaregivers =>
      _notificationService.nearbyCaregivers;

  void clearNearbyCaregivers() {
    _notificationService.clearNearbyCaregivers();
    _caregiverMarkers.clear();
    _caregiverMarkersCache.clear();
    selectedCaregiverNearby = null;
    _lastCaregiverIds.clear();
    notifyListeners();
  }

  // Cargar mascotas del usuario
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
      await getCurrentLocation();
    }
  }

  // Obtener ubicación actual
  Future<void> getCurrentLocation() async {
    if (isLoadingLocation) return;

    try {
      isLoadingLocation = true;
      notifyListeners();

      final permission = await Permission.location.request();
      if (!permission.isGranted) return;

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (currentPosition != null) {
        initialCameraPosition = CameraPosition(
          target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          zoom: 14.0,
        );

        if (mapController.isCompleted) {
          final controller = await mapController.future;
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(currentPosition!.latitude, currentPosition!.longitude),
              14.0,
            ),
          );
        }

        _addUserLocationMarker();
        debugPrint('[HomeController] Ubicación obtenida: ${currentPosition!.latitude}, ${currentPosition!.longitude}');
      }
    } catch (e) {
      print("Error obteniendo ubicación: $e");
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Agregar marcador de ubicación del usuario
  void _addUserLocationMarker() {
    if (currentPosition == null) return;

    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: 'Tu ubicación',
          snippet: 'Estás aquí',
        ),
      ),
    );

    circles.clear();
    circles.add(
      Circle(
        circleId: const CircleId('search_area'),
        center: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        radius: 2000,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      ),
    );
  }

  // Inicializar servicio de notificaciones
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

  // Centrar mapa en todos los cuidadores
  Future<void> centerMapOnCaregivers() async {
    if (!mapController.isCompleted || nearbyCaregivers.isEmpty) return;

    final controller = await mapController.future;

    if (nearbyCaregivers.length == 1) {
      final caregiver = nearbyCaregivers.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(caregiver.latitude, caregiver.longitude),
          15.0,
        ),
      );
    } else {
      final bounds = _calculateBounds(nearbyCaregivers);
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  // Calcular límites para mostrar todos los cuidadores
  LatLngBounds _calculateBounds(List<CaregiversNearbyResponse> caregivers) {
    double minLat = caregivers.first.latitude;
    double maxLat = caregivers.first.latitude;
    double minLng = caregivers.first.longitude;
    double maxLng = caregivers.first.longitude;

    for (final caregiver in caregivers) {
      minLat = minLat < caregiver.latitude ? minLat : caregiver.latitude;
      maxLat = maxLat > caregiver.latitude ? maxLat : caregiver.latitude;
      minLng = minLng < caregiver.longitude ? minLng : caregiver.longitude;
      maxLng = maxLng > caregiver.longitude ? maxLng : caregiver.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _notificationService.removeListener(_onCaregiverNotificationUpdate);
    super.dispose();
  }
}