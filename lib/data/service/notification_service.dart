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

  // Control de actualizaciones en batch
  Timer? _batchUpdateTimer;
  final Set<int> _pendingUpdates = {};
  final Set<int> _pendingRemovals = {};

  // Control de reconexión automática mejorado
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // NUEVO: Control de estado de conexión
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  DateTime? _lastDisconnectTime;
  static const Duration _minimumReconnectInterval = Duration(seconds: 2);

  // Cache de datos
  final Map<int, CaregiversNearbyResponse> _caregiverCache = {};

  // Getters
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
    _shouldReconnect = true;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    if (_authToken == null || _caregiverId == null || _serverUrl == null) {
      _updateConnectionStatus('Faltan credenciales');
      return;
    }

    // NUEVO: Prevenir múltiples conexiones simultáneas
    if (_isConnecting) {
      debugPrint('[NotificationService] Ya hay una conexión en progreso, ignorando...');
      return;
    }

    // NUEVO: Verificar intervalo mínimo entre reconexiones
    if (_lastDisconnectTime != null) {
      final timeSinceDisconnect = DateTime.now().difference(_lastDisconnectTime!);
      if (timeSinceDisconnect < _minimumReconnectInterval) {
        debugPrint('[NotificationService] Esperando antes de reconectar...');
        _scheduleReconnect();
        return;
      }
    }

    _isConnecting = true;

    // NUEVO: Cancelar cliente anterior de forma más robusta
    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
      } catch (e) {
        debugPrint('[NotificationService] Error al desactivar cliente anterior: $e');
      }
      _stompClient = null;
    }

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
            debugPrint('[NotificationService] Error de WebSocket: $error');
            _handleConnectionError('Error de WebSocket');
          },
          onStompError: (frame) {
            debugPrint('[NotificationService] Error STOMP: ${frame.body}');
            _handleConnectionError('Error STOMP');
          },
          onDisconnect: (frame) {
            debugPrint('[NotificationService] Desconectado del WebSocket');
            _handleDisconnection();
          },
          // NUEVO: Configuración de headers mejorada
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $_authToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          stompConnectHeaders: {
            'Authorization': 'Bearer $_authToken',
            'login': _userId ?? '',
            'passcode': _authToken ?? '',
            'heart-beat': '10000,10000', // NUEVO: Heartbeat para mantener conexión
          },
          // NUEVO: Configuración de timeouts
          connectionTimeout: const Duration(seconds: 10),
        )
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _isConnecting = false; // NUEVO: Marcar que ya no estamos conectando
    _reconnectAttempts = 0;
    _updateConnectionStatus('Conectado');

    final caregiverTopic = '/topic/offers/$_caregiverId';
    final ownerTopic = '/topic/notifications/$_userId';

    debugPrint('[NotificationService] Conectado, suscribiéndose a: $caregiverTopic');
    debugPrint('[NotificationService] Conectado, suscribiéndose a: $ownerTopic');

    try {
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
    } catch (e) {
      debugPrint('[NotificationService] Error en suscripción: $e');
      _handleConnectionError('Error en suscripción');
      return;
    }

    notifyListeners();
  }

  // NUEVO: Método para manejar errores de conexión
  void _handleConnectionError(String errorType) {
    _isConnected = false;
    _isConnecting = false;
    _updateConnectionStatus(errorType);

    if (_shouldReconnect) {
      _scheduleReconnect();
    }

    notifyListeners();
  }

  // NUEVO: Método para manejar desconexiones
  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    _lastDisconnectTime = DateTime.now();
    _updateConnectionStatus('Desconectado');

    if (_shouldReconnect) {
      _scheduleReconnect();
    }

    notifyListeners();
  }

  // Programar reconexión automática mejorada
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[NotificationService] Máximo de intentos de reconexión alcanzado');
      _shouldReconnect = false;
      _updateConnectionStatus('Conexión fallida');
      return;
    }

    _reconnectTimer?.cancel();

    // NUEVO: Backoff exponencial para reconexión
    final delaySeconds = _reconnectDelay.inSeconds * (_reconnectAttempts + 1);
    final delay = Duration(seconds: delaySeconds.clamp(2, 30));

    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect && !_isConnecting && !_isConnected) {
        _reconnectAttempts++;
        debugPrint('[NotificationService] Intento de reconexión ${_reconnectAttempts}/${_maxReconnectAttempts}');
        _connectToWebSocket();
      }
    });
  }

  // Procesamiento en batch de notificaciones
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

  void _updateCaregiverData(Map<String, dynamic> data) {
    try {
      final caregiverId = data['caregiverId'] as int;
      final caregiver = CaregiversNearbyResponse.fromJson(data);

      final updatedCaregiver = CaregiversNearbyResponse(
        id: caregiverId,
        userName: caregiver.userName,
        imgUrl: caregiver.imgUrl,
        latitude: caregiver.latitude,
        longitude: caregiver.longitude,
      );

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

  void _scheduleBatchUpdate() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(const Duration(milliseconds: 50), () {
      _processBatchUpdates();
    });
  }

  void _processBatchUpdates() {
    bool hasChanges = false;

    if (_pendingRemovals.isNotEmpty) {
      for (final caregiverId in _pendingRemovals) {
        _removeCaregiverFromListOptimized(caregiverId);
      }
      _pendingRemovals.clear();
      hasChanges = true;
    }

    if (_pendingUpdates.isNotEmpty) {
      _pendingUpdates.clear();
      hasChanges = true;
    }

    if (hasChanges) {
      debugPrint('[NotificationService] Batch update procesado, notificando listeners');
      notifyListeners();
    }
  }

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
    _caregiverCache.clear();
    notifyListeners();
  }

  void removeCaregiverById(int caregiverId) {
    _removeCaregiverFromListOptimized(caregiverId);
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

  // NUEVO: Método de reconexión manual mejorado
  void reconnect() {
    debugPrint('[NotificationService] Reconectando manualmente...');
    _reconnectAttempts = 0;
    _shouldReconnect = true;
    _isConnecting = false;
    _lastDisconnectTime = null;

    if (_authToken != null && _userId != null && _caregiverId != null && _serverUrl != null) {
      _connectToWebSocket();
    }
  }

  void disconnect() {
    _shouldReconnect = false; // NUEVO: Evitar reconexión automática
    _reconnectTimer?.cancel();
    _batchUpdateTimer?.cancel();

    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
      } catch (e) {
        debugPrint('[NotificationService] Error al desconectar: $e');
      }
      _stompClient = null;
    }

    _isConnected = false;
    _isConnecting = false;
    _updateConnectionStatus('Desconectado');
    debugPrint('[NotificationService] Servicio de notificaciones desconectado');
  }

  @override
  void dispose() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _batchUpdateTimer?.cancel();
    _caregiverCache.clear();
    _pendingUpdates.clear();
    _pendingRemovals.clear();
    disconnect();
    super.dispose();
  }
}