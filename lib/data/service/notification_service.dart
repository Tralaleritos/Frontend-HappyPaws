import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

import '../models/notifications/caregiver_nearby_response.dart';
import '../models/notifications/offer_response.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  StompClient? _stompClient;
  List<OfferResponse> _notifications = [];
  int _unreadCount = 0;
  bool _isConnected = false;
  String _connectionStatus = 'Desconectado';
  String? _authToken;
  String? _userId;
  int? _caregiverId;
  String? _serverUrl;
  List<CaregiversNearbyResponse> _nearbyCaregivers = [];

  // OPTIMIZACIÓN: Control de actualizaciones en batch
  Timer? _batchUpdateTimer;
  final Set<int> _pendingUpdates = {};
  final Set<int> _pendingRemovals = {};

  // OPTIMIZACIÓN: Control de reconexión automática
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  // OPTIMIZACIÓN: Cache de datos para evitar búsquedas repetitivas
  final Map<int, CaregiversNearbyResponse> _caregiverCache = {};

  List<OfferResponse> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  List<CaregiversNearbyResponse> get nearbyCaregivers => List.unmodifiable(_nearbyCaregivers);

  void initialize({
    required String authToken,
    required String userId,
    required int caregiverId,
    required String serverUrl
  }) {
    _authToken = authToken;
    _userId = userId;
    _caregiverId = caregiverId;
    _serverUrl = serverUrl;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    if (_authToken == null || _caregiverId == null || _serverUrl == null) {
      _updateConnectionStatus('Faltan credenciales');
      return;
    }

    _stompClient?.deactivate();
    final wsUrl = '$_serverUrl/happy';
    debugPrint('[NotificationService] Conectando a WebSocket: $wsUrl');

    _stompClient = StompClient(
        config: StompConfig.SockJS(
            url: wsUrl,
            onConnect: _onConnect,
            beforeConnect: () async {
              _updateConnectionStatus('Conectando...');
              debugPrint('[NotificationService] Iniciando conexión WebSocket...');
            },
            onWebSocketError: (error) {
              _updateConnectionStatus('Error de WebSocket');
              _isConnected = false;
              debugPrint('[NotificationService] Error de WebSocket: $error');
              _scheduleReconnect();
              notifyListeners();
            },
            onStompError: (frame) {
              _updateConnectionStatus('Error STOMP');
              _isConnected = false;
              debugPrint('[NotificationService] Error STOMP: ${frame.body}');
              _scheduleReconnect();
              notifyListeners();
            },
            onDisconnect: (frame) {
              _updateConnectionStatus('Desconectado');
              _isConnected = false;
              debugPrint('[NotificationService] Desconectado del WebSocket');
              _scheduleReconnect();
              notifyListeners();
            },
            webSocketConnectHeaders: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json'
            },
            stompConnectHeaders: {
              'Authorization': 'Bearer $_authToken',
              'login': _userId ?? '',
              'passcode': _authToken ?? ''
            }
        )
    );
    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _reconnectAttempts = 0; // Reset contador de reconexión
    _updateConnectionStatus('Conectado');

    final caregiverTopic = '/topic/offers/$_caregiverId';
    final ownerTopic = '/topic/notifications/$_userId';

    debugPrint('[NotificationService] Conectado, suscribiéndose a: $caregiverTopic');
    debugPrint('[NotificationService] Conectado, suscribiéndose a: $ownerTopic');

    _stompClient!.subscribe(
        destination: caregiverTopic,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'id': 'sub-$_caregiverId'
        },
        callback: _onOfferReceived
    );

    _stompClient!.subscribe(
        destination: ownerTopic,
        headers: {
          'Authorization': 'Bearer $_authToken',
          'id': 'sub-notify-$_userId'
        },
        callback: _onCaregiverNotificationReceived
    );

    debugPrint('[NotificationService] Suscripción completada exitosamente');
    notifyListeners();
  }

  // OPTIMIZACIÓN: Programar reconexión automática
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[NotificationService] Máximo de intentos de reconexión alcanzado');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      debugPrint('[NotificationService] Intento de reconexión ${_reconnectAttempts}/${_maxReconnectAttempts}');
      _connectToWebSocket();
    });
  }

  // OPTIMIZACIÓN: Procesamiento en batch de notificaciones
  void _onCaregiverNotificationReceived(StompFrame frame) {
    debugPrint('[NotificationService] Mensaje de notificación recibido: ${frame.body}');
    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);
        final caregiverId = data['caregiverId'] as int?;

        if (caregiverId == null) {
          debugPrint('[NotificationService] CaregiverId no válido en el mensaje');
          return;
        }

        if (data['type'] == 'CAREGIVER_UNAVAILABLE') {
          debugPrint('[NotificationService] Cuidador $caregiverId marcado como no disponible');
          _pendingRemovals.add(caregiverId);
          _scheduleBatchUpdate();
        } else if (data['type'] == 'CAREGIVER_AVAILABLE') {
          debugPrint('[NotificationService] Cuidador $caregiverId disponible');
          _pendingUpdates.add(caregiverId);
          _updateCaregiverData(data);
          _scheduleBatchUpdate();
        }
      } catch (e) {
        debugPrint('[NotificationService] Error al procesar notificación: $e');
      }
    }
  }

  // OPTIMIZACIÓN: Actualizar datos del cuidador de forma inmediata
  void _updateCaregiverData(Map<String, dynamic> data) {
    try {
      final caregiverId = data['caregiverId'] as int;
      final caregiver = CaregiversNearbyResponse.fromJson(data);

      // Crear nueva instancia con el ID correcto
      final updatedCaregiver = CaregiversNearbyResponse(
        id: caregiverId,
        userName: caregiver.userName,
        imgUrl: caregiver.imgUrl,
        latitude: caregiver.latitude,
        longitude: caregiver.longitude,
      );

      // OPTIMIZACIÓN: Usar cache para búsquedas más rápidas
      final existingIndex = _caregiverCache.containsKey(caregiverId)
          ? _nearbyCaregivers.indexWhere((c) => c.id == caregiverId)
          : -1;

      if (existingIndex == -1) {
        _nearbyCaregivers.insert(0, updatedCaregiver);
        _caregiverCache[caregiverId] = updatedCaregiver;
        debugPrint('[NotificationService] Nuevo cuidador agregado: ${updatedCaregiver.userName} (ID: $caregiverId)');
      } else {
        _nearbyCaregivers[existingIndex] = updatedCaregiver;
        _caregiverCache[caregiverId] = updatedCaregiver;
        debugPrint('[NotificationService] Cuidador actualizado: ${updatedCaregiver.userName} (ID: $caregiverId)');
      }
    } catch (e) {
      debugPrint('[NotificationService] Error actualizando datos del cuidador: $e');
    }
  }

  // OPTIMIZACIÓN: Programar actualizaciones en batch
  void _scheduleBatchUpdate() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(const Duration(milliseconds: 50), () {
      _processBatchUpdates();
    });
  }

  // OPTIMIZACIÓN: Procesar actualizaciones en batch
  void _processBatchUpdates() {
    bool hasChanges = false;

    // Procesar remociones
    if (_pendingRemovals.isNotEmpty) {
      for (final caregiverId in _pendingRemovals) {
        _removeCaregiverFromListOptimized(caregiverId);
      }
      _pendingRemovals.clear();
      hasChanges = true;
    }

    // Procesar actualizaciones (ya procesadas en _updateCaregiverData)
    if (_pendingUpdates.isNotEmpty) {
      _pendingUpdates.clear();
      hasChanges = true;
    }

    if (hasChanges) {
      debugPrint('[NotificationService] Batch update procesado, notificando listeners');
      notifyListeners();
    }
  }

  // OPTIMIZACIÓN: Versión optimizada de remoción usando cache
  void _removeCaregiverFromListOptimized(int caregiverId) {
    if (_caregiverCache.containsKey(caregiverId)) {
      final initialLength = _nearbyCaregivers.length;
      _nearbyCaregivers.removeWhere((caregiver) => caregiver.id == caregiverId);
      _caregiverCache.remove(caregiverId);

      final removedCount = initialLength - _nearbyCaregivers.length;
      if (removedCount > 0) {
        debugPrint('[NotificationService] Removidos $removedCount cuidador(es) con ID: $caregiverId');
      }
    } else {
      debugPrint('[NotificationService] No se encontró cuidador con ID: $caregiverId en cache');
    }
  }

  // Método legacy mantenido para compatibilidad
  void _removeCaregiverFromList(int caregiverId) {
    final initialLength = _nearbyCaregivers.length;
    _nearbyCaregivers.removeWhere((caregiver) => caregiver.id == caregiverId);
    _caregiverCache.remove(caregiverId);
    final removedCount = initialLength - _nearbyCaregivers.length;

    if (removedCount > 0) {
      debugPrint('[NotificationService] Removidos $removedCount cuidador(es) con ID: $caregiverId');
    } else {
      debugPrint('[NotificationService] No se encontró cuidador con ID: $caregiverId para remover');
    }
  }

  void _onOfferReceived(StompFrame frame) {
    debugPrint('[NotificationService] ¡Mensaje de oferta recibido!');
    debugPrint('[NotificationService] Contenido del frame: ${frame.body}');

    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);
        debugPrint('[NotificationService] Datos JSON parseados: $data');

        final offer = OfferResponse.fromJson(data);
        debugPrint('[NotificationService] OfferResponse creada: ID=${offer.id}, Descripción=${offer.description}');

        _notifications.insert(0, offer);
        _unreadCount++;

        debugPrint('[NotificationService] Notificación añadida a la lista. Total no leídas: $_unreadCount');
        notifyListeners();
      } catch (e) {
        debugPrint('[NotificationService] ERROR al procesar la notificación: $e');
        debugPrint('[NotificationService] Datos del frame: ${frame.body}');
      }
    } else {
      debugPrint('[NotificationService] ERROR: Frame recibido sin contenido');
    }
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    notifyListeners();
  }

  void markAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  void clearNearbyCaregivers() {
    _nearbyCaregivers.clear();
    _caregiverCache.clear(); // OPTIMIZACIÓN: Limpiar también el cache
    notifyListeners();
  }

  // Método manual para remover un cuidador específico (útil para testing o casos especiales)
  void removeCaregiverById(int caregiverId) {
    _removeCaregiverFromList(caregiverId);
    notifyListeners();
  }

  void acceptOffer(OfferResponse offer) {
    if (_stompClient != null && _isConnected && _authToken != null && _caregiverId != null) {
      final acceptMessage = {
        'caregiverId': _caregiverId,
        'offerId': offer.id,
        'action': 'accept',
        'timestamp': DateTime.now().toIso8601String()
      };

      _stompClient!.send(
          destination: '/app/accept-offer',
          body: json.encode(acceptMessage),
          headers: {
            'Authorization': 'Bearer $_authToken',
            'Content-Type': 'application/json'
          }
      );

      debugPrint('[NotificationService] Mensaje de aceptación enviado para oferta ${offer.id}');
    }
  }

  void reconnect() {
    debugPrint('[NotificationService] Reconectando manualmente...');
    _reconnectAttempts = 0; // Reset contador para reconexión manual
    if (_authToken != null && _userId != null && _caregiverId != null && _serverUrl != null) {
      _connectToWebSocket();
    }
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
    _reconnectTimer?.cancel(); // OPTIMIZACIÓN: Cancelar timer de reconexión
    _batchUpdateTimer?.cancel(); // OPTIMIZACIÓN: Cancelar timer de batch update
    _updateConnectionStatus('Desconectado');
    debugPrint('[NotificationService] Servicio de notificaciones desconectado');
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _batchUpdateTimer?.cancel();
    _caregiverCache.clear();
    _pendingUpdates.clear();
    _pendingRemovals.clear();
    disconnect();
    super.dispose();
  }
}