import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/models/notifications/caregiver_nearby_response.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:happyp/data/service/notification_service.dart';

/// Controlador principal para la pantalla Home
/// Maneja la lógica de ubicación, mapas, mascotas y cuidadores
class HomeController with ChangeNotifier {
  // =====================================
  // SERVICIOS Y DEPENDENCIAS
  // =====================================

  final AuthService _authService;
  final PetService _petService = PetService();
  final NotificationService _notificationService = NotificationService();

  // =====================================
  // CONSTANTES
  // =====================================

  static const Duration _locationUpdateInterval = Duration(minutes: 5);
  static const Duration _updateDebounceDelay = Duration(milliseconds: 100);
  static const double _searchRadius = 2000.0;
  static const double _markerSize = 30.0;
  static const int _locationTimeoutSeconds = 15;

  // =====================================
  // ESTADO DEL CONTROLADOR
  // =====================================

  bool _isInitialized = false;
  bool isLoadingPets = false;
  bool isLoadingLocation = false;
  bool isSearching = false;
  bool showServiceForm = false;

  // =====================================
  // TIMERS Y GESTIÓN DE ACTUALIZACIONES
  // =====================================

  Timer? _locationUpdateTimer;
  Timer? _updateTimer;
  bool _pendingUpdate = false;

  // =====================================
  // DATOS DEL USUARIO Y MASCOTAS
  // =====================================

  String? ownerId;
  List<Pet> userPets = [];
  Pet? selectedPet;

  // =====================================
  // CONFIGURACIÓN DE SERVICIO
  // =====================================

  String selectedServiceType = 'Paseo';
  DateTime serviceDate = DateTime.now();
  TimeOfDay serviceTime = TimeOfDay.now();
  int serviceDuration = 60;
  double servicePrice = 35.00;

  // =====================================
  // UBICACIÓN Y MAPA
  // =====================================

  Position? currentPosition;
  final Completer<GoogleMapController> mapController = Completer();

  // Posición inicial del mapa (Lima, Perú)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-12.0464, -77.0428),
    zoom: 14.0,
  );

  CameraPosition get initialCameraPosition => _initialCameraPosition;

  // =====================================
  // MARCADORES Y ELEMENTOS DEL MAPA
  // =====================================

  final Set<Marker> _userMarkers = {};
  final Set<Circle> _circles = {};
  final Set<Marker> _caregiverMarkers = {};
  final Map<int, Marker> _caregiverMarkersCache = {};

  // Marcadores personalizados
  BitmapDescriptor? _caregiverIcon;
  BitmapDescriptor? _selectedCaregiverIcon;

  // =====================================
  // CUIDADORES
  // =====================================

  dynamic selectedCaregiverNearby;
  Set<int> _lastCaregiverIds = {};

  // =====================================
  // GETTERS PÚBLICOS
  // =====================================

  Set<Marker> get markers => _userMarkers;
  Set<Circle> get circles => _circles;
  Set<Marker> get allMarkers => {..._userMarkers, ..._caregiverMarkers};

  List<CaregiversNearbyResponse> get nearbyCaregivers =>
      _notificationService.nearbyCaregivers;

  PetService get petService => _petService;

  bool get hasLocation => currentPosition != null;
  bool get isInitialized => _isInitialized;

  Map<String, double>? get locationAsMap {
    if (currentPosition == null) return null;
    return {
      'latitude': currentPosition!.latitude,
      'longitude': currentPosition!.longitude,
    };
  }

  // =====================================
  // CONSTRUCTOR E INICIALIZACIÓN
  // =====================================

  HomeController(this._authService) {
    _initializeController();
  }

  /// Inicialización principal del controlador
  Future<void> _initializeController() async {
    try {
      debugPrint('[HomeController] Iniciando inicialización...');

      // Inicializar componentes en orden
      await _loadCustomMarkers();
      await _setupAuthentication();
      _setupNotificationListener();
      await _initializeLocationServices();
      await loadUserPets();

      _isInitialized = true;
      debugPrint('[HomeController] Inicialización completa exitosa');

    } catch (e) {
      debugPrint('[HomeController] Error en inicialización: $e');
      rethrow;
    }
  }

  /// Configurar autenticación y servicios asociados
  Future<void> _setupAuthentication() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception("Token de autenticación no disponible");
    }

    _petService.setAuthToken(token);

    final user = _authService.currentUser;
    if (user?.id.isNotEmpty == true) {
      ownerId = user!.id;
      debugPrint('[HomeController] Owner ID: $ownerId');
      await _initializeNotificationService(token, user.id);
    } else {
      throw Exception("Usuario no válido");
    }
  }

  /// Inicializar servicios de ubicación
  Future<void> _initializeLocationServices() async {
    debugPrint('[HomeController] Inicializando servicios de ubicación...');

    final locationObtained = await getCurrentLocation();
    if (locationObtained && currentPosition != null) {
      await _updateLocationInBackend();
      _addUserLocationMarker();
      _startLocationUpdates();
      debugPrint('[HomeController] Servicios de ubicación inicializados');
    } else {
      debugPrint('[HomeController] No se pudo obtener ubicación inicial');
    }
  }

  // =====================================
  // MÉTODOS PÚBLICOS PRINCIPALES
  // =====================================

  /// Llamar cuando la pantalla Home aparece
  Future<void> onHomeAppear() async {
    debugPrint('[HomeController] Home apareció');

    if (!_isInitialized) {
      await _initializeController();
    } else {
      await forceLocationUpdate();
    }
  }

  /// Forzar actualización de ubicación desde la UI
  Future<bool> forceLocationUpdate() async {
    debugPrint('[HomeController] Forzando actualización de ubicación...');

    final locationObtained = await getCurrentLocation();
    if (locationObtained && currentPosition != null) {
      final backendUpdated = await _updateLocationInBackend();
      if (backendUpdated) {
        _addUserLocationMarker();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  // =====================================
  // GESTIÓN DE UBICACIÓN
  // =====================================

  /// Obtener ubicación actual del usuario
  Future<bool> getCurrentLocation() async {
    if (isLoadingLocation) return false;

    try {
      isLoadingLocation = true;
      notifyListeners();

      debugPrint('[HomeController] Obteniendo ubicación...');

      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        debugPrint('[HomeController] Permisos de ubicación denegados');
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: _locationTimeoutSeconds),
      );

      currentPosition = position;
      await _updateMapCamera(position);

      debugPrint('[HomeController] Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      return true;

    } catch (e) {
      debugPrint('[HomeController] Error obteniendo ubicación: $e');
      return false;
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Solicitar permisos de ubicación
  Future<bool> _requestLocationPermission() async {
    // Verificar servicio de ubicación
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[HomeController] Servicio de ubicación deshabilitado');
      return false;
    }

    // Verificar y solicitar permisos
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[HomeController] Permisos denegados');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[HomeController] Permisos denegados permanentemente');
      return false;
    }

    return true;
  }

  /// Actualizar cámara del mapa
  Future<void> _updateMapCamera(Position position) async {
    if (mapController.isCompleted) {
      final controller = await mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

  /// Iniciar actualizaciones automáticas de ubicación
  void _startLocationUpdates() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(_locationUpdateInterval, (timer) async {
      debugPrint('[HomeController] Actualización automática de ubicación');
      await _updateLocationAndNotifyBackend();
    });
  }

  /// Actualizar ubicación en el backend
  Future<bool> _updateLocationInBackend() async {
    try {
      if (_authService.currentUser == null || currentPosition == null) {
        return false;
      }

      final success = await _authService.updateUserLocation(
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
      );

      if (success) {
        debugPrint('[HomeController] Ubicación actualizada en backend');
      }
      return success;

    } catch (e) {
      debugPrint('[HomeController] Error actualizando ubicación: $e');
      return false;
    }
  }

  /// Actualización completa de ubicación
  Future<void> _updateLocationAndNotifyBackend() async {
    try {
      final locationObtained = await getCurrentLocation();
      if (locationObtained && currentPosition != null) {
        await _updateLocationInBackend();
        _addUserLocationMarker();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[HomeController] Error en actualización completa: $e');
    }
  }

  // =====================================
  // GESTIÓN DE MARCADORES
  // =====================================

  /// Cargar marcadores personalizados
  Future<void> _loadCustomMarkers() async {
    try {
      debugPrint('[HomeController] Cargando marcadores personalizados...');

      final futures = await Future.wait([
        _createCustomMarker(Icons.pets, Colors.blue, Colors.white),
        _createCustomMarker(Icons.pets, Colors.orange, Colors.white),
      ]);

      _caregiverIcon = futures[0];
      _selectedCaregiverIcon = futures[1];

      debugPrint('[HomeController] Marcadores cargados exitosamente');

    } catch (e) {
      debugPrint('[HomeController] Error cargando marcadores: $e');
      _caregiverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      _selectedCaregiverIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  /// Crear marcador personalizado
  Future<BitmapDescriptor> _createCustomMarker(
      IconData iconData,
      Color backgroundColor,
      Color iconColor,
      ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = backgroundColor;

    // Dibujar círculo de fondo
    canvas.drawCircle(
      Offset(_markerSize, _markerSize),
      _markerSize,
      paint,
    );

    // Dibujar icono
    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 35,
          fontFamily: iconData.fontFamily,
          color: iconColor,
        ),
      ),
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        _markerSize - textPainter.width / 2,
        _markerSize - textPainter.height / 2,
      ),
    );

    // Convertir a imagen
    final ui.Image markerAsImage = await pictureRecorder
        .endRecording()
        .toImage((_markerSize * 2).toInt(), (_markerSize * 2).toInt());

    final ByteData? byteData = await markerAsImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// Agregar marcador de ubicación del usuario
  void _addUserLocationMarker() {
    if (currentPosition == null) return;

    _userMarkers.clear();
    _userMarkers.add(
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

    _circles.clear();
    _circles.add(
      Circle(
        circleId: const CircleId('search_area'),
        center: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        radius: _searchRadius,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue.withOpacity(0.3),
        strokeWidth: 2,
      ),
    );
  }

  // =====================================
  // GESTIÓN DE CUIDADORES
  // =====================================

  /// Configurar listener de notificaciones
  void _setupNotificationListener() {
    _notificationService.addListener(_onCaregiverNotificationUpdate);
  }

  /// Manejar actualización de notificaciones de cuidadores
  void _onCaregiverNotificationUpdate() {
    debugPrint('[HomeController] Notificación de cuidador recibida');
    _scheduleMarkerUpdate();
  }

  /// Programar actualización de marcadores con debounce
  void _scheduleMarkerUpdate() {
    if (_pendingUpdate) return;

    _pendingUpdate = true;
    _updateTimer?.cancel();

    _updateTimer = Timer(_updateDebounceDelay, () {
      _pendingUpdate = false;
      _updateCaregiverMarkersOptimized();
      notifyListeners();
    });
  }

  /// Actualización optimizada de marcadores de cuidadores
  void _updateCaregiverMarkersOptimized() {
    final caregivers = nearbyCaregivers;
    final currentIds = caregivers.map((c) => c.id).toSet();

    final toAdd = currentIds.difference(_lastCaregiverIds);
    final toRemove = _lastCaregiverIds.difference(currentIds);
    final toUpdate = currentIds.intersection(_lastCaregiverIds);

    debugPrint('[HomeController] Marcadores - Agregar: ${toAdd.length}, Remover: ${toRemove.length}');

    // Remover marcadores obsoletos
    for (final id in toRemove) {
      _caregiverMarkers.removeWhere((marker) =>
      marker.markerId.value == 'caregiver_$id');
      _caregiverMarkersCache.remove(id);

      if (selectedCaregiverNearby?.id == id) {
        selectedCaregiverNearby = null;
      }
    }

    // Actualizar marcadores existentes y nuevos
    for (final caregiver in caregivers) {
      final needsUpdate = toAdd.contains(caregiver.id) ||
          toUpdate.contains(caregiver.id) ||
          (selectedCaregiverNearby?.id == caregiver.id);

      if (needsUpdate) {
        _updateSingleCaregiverMarker(caregiver);
      }
    }

    _lastCaregiverIds = currentIds;
  }

  /// Actualizar un marcador específico de cuidador
  void _updateSingleCaregiverMarker(CaregiversNearbyResponse caregiver) {
    final isSelected = selectedCaregiverNearby?.id == caregiver.id;

    final marker = Marker(
      markerId: MarkerId('caregiver_${caregiver.id}'),
      position: LatLng(caregiver.latitude, caregiver.longitude),
      icon: isSelected
          ? (_selectedCaregiverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange))
          : (_caregiverIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)),
      infoWindow: InfoWindow(
        title: caregiver.userName,
        snippet: 'Cuidador disponible - Toca para más info',
      ),
      onTap: () => _onCaregiverMarkerTapped(caregiver),
    );

    _caregiverMarkers.removeWhere((m) =>
    m.markerId.value == 'caregiver_${caregiver.id}');
    _caregiverMarkers.add(marker);
    _caregiverMarkersCache[caregiver.id] = marker;
  }

  /// Manejar toque en marcador de cuidador
  void _onCaregiverMarkerTapped(CaregiversNearbyResponse caregiver) {
    selectCaregiver(caregiver);
    _animateToCaregiver(caregiver);
  }

  /// Seleccionar cuidador
  void selectCaregiver(dynamic caregiver) {
    final previousSelected = selectedCaregiverNearby;
    selectedCaregiverNearby = caregiver;

    if (previousSelected?.id != caregiver?.id) {
      debugPrint('[HomeController] Cuidador seleccionado: ${caregiver?.userName}');

      // Actualizar solo los marcadores afectados
      if (previousSelected != null) {
        _updateSingleCaregiverMarker(previousSelected);
      }
      if (caregiver != null) {
        _updateSingleCaregiverMarker(caregiver);
      }

      notifyListeners();
    }
  }

  /// Animar cámara hacia cuidador
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

  /// Centrar mapa en todos los cuidadores
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

  /// Calcular límites del mapa para mostrar todos los cuidadores
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

  /// Limpiar cuidadores cercanos
  void clearNearbyCaregivers() {
    _notificationService.clearNearbyCaregivers();
    _caregiverMarkers.clear();
    _caregiverMarkersCache.clear();
    selectedCaregiverNearby = null;
    _lastCaregiverIds.clear();
    notifyListeners();
  }

  // =====================================
  // GESTIÓN DE MASCOTAS
  // =====================================

  /// Cargar mascotas del usuario
  Future<void> loadUserPets() async {
    isLoadingPets = true;
    notifyListeners();

    try {
      userPets = await _petService.getUserPets();
      if (userPets.isNotEmpty) {
        selectedPet = userPets.first;
      }
      debugPrint('[HomeController] Mascotas cargadas: ${userPets.length}');
    } catch (e) {
      debugPrint('[HomeController] Error cargando mascotas: $e');
    } finally {
      isLoadingPets = false;
      notifyListeners();
    }
  }

  /// Seleccionar mascota
  void selectPet(Pet pet) {
    selectedPet = pet;
    notifyListeners();
  }

  // =====================================
  // GESTIÓN DE SERVICIOS
  // =====================================

  /// Cambiar tipo de servicio
  void changeServiceType(String type) {
    selectedServiceType = type;
    notifyListeners();
  }

  // =====================================
  // INICIALIZACIÓN DE SERVICIOS
  // =====================================

  /// Inicializar servicio de notificaciones
  Future<void> _initializeNotificationService(String authToken, String userId) async {
    try {
      _notificationService.initialize(
        authToken: authToken,
        userId: userId,
        caregiverId: int.parse(userId),
        serverUrl: ApiConstants.BASE_URL,
      );
      debugPrint('[HomeController] NotificationService inicializado');
    } catch (e) {
      debugPrint('[HomeController] Error inicializando NotificationService: $e');
    }
  }

  // =====================================
  // LIMPIEZA Y DISPOSE
  // =====================================

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _updateTimer?.cancel();
    _notificationService.removeListener(_onCaregiverNotificationUpdate);
    super.dispose();
  }
}