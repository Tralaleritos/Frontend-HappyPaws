import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../models/notifications/caregiver_nearby_response.dart';
import '../models/notifications/offer_response.dart';
import '../models/offers/offer_accept_response.dart';
import '../models/offers/offer_completed_response.dart';
import '../models/offers/offer_unavailable_response.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  StompClient? _stompClient;
  List<OfferResponse> _notifications = [];
  List<OfferAcceptedResponse> _notificationsAccepted = [];
  int _unreadCount = 0;
  bool _isConnected = false;
  String _connectionStatus = 'Desconectado';
  String? _authToken;
  String? _userId;
  int? _caregiverId;
  String? _serverUrl;
  List<CaregiversNearbyResponse> _nearbyCaregivers = [];
  Timer? _batchUpdateTimer;
  final Set<int> _pendingUpdates = {};
  final Set<int> _pendingRemovals = {};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  DateTime? _lastDisconnectTime;
  static const Duration _minimumReconnectInterval = Duration(seconds: 2);
  final Map<int, CaregiversNearbyResponse> _caregiverCache = {};

  Function(OfferAcceptedResponse)? _onOfferAccepted;
  Function(OfferUnavailableResponse)? _onOfferUnavailable;
  Function(OfferCompletedResponse)? _onOfferCompleted;

  // Getters
  List<OfferResponse> get notifications => List.unmodifiable(_notifications);
  List<OfferAcceptedResponse> get notificationsAccepted => List.unmodifiable(_notificationsAccepted);
  int get unreadCount => _unreadCount;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;
  List<CaregiversNearbyResponse> get nearbyCaregivers => List.unmodifiable(_nearbyCaregivers);

  // Callback setters
  void setOnOfferAccepted(Function(OfferAcceptedResponse) callback) {
    _onOfferAccepted = callback;
  }

  void setOnOfferUnavailable(Function(OfferUnavailableResponse) callback) {
    _onOfferUnavailable = callback;
  }

  void setOnOfferCompleted(Function(OfferCompletedResponse) callback) {
    _onOfferCompleted = callback;
  }

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

  // FUNCIÓN RECONNECT QUE FALTABA
  void reconnect() {
    debugPrint('[NotificationService] Reconexión manual solicitada');
    _shouldReconnect = true;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    if (_isConnecting) {
      debugPrint('[NotificationService] Ya hay una conexión en progreso');
      return;
    }

    if (_isConnected) {
      debugPrint('[NotificationService] Ya está conectado');
      return;
    }

    _connectToWebSocket();
  }

  // FUNCIÓN CLEAR NEARBY CAREGIVERS QUE FALTABA
  void clearNearbyCaregivers() {
    debugPrint('[NotificationService] Limpiando lista de cuidadores cercanos');
    _nearbyCaregivers.clear();
    _caregiverCache.clear();
    _pendingUpdates.clear();
    _pendingRemovals.clear();
    _batchUpdateTimer?.cancel();
    notifyListeners();
  }

  void _connectToWebSocket() {
    if (_authToken == null || _caregiverId == null || _serverUrl == null) {
      _updateConnectionStatus('Faltan credenciales');
      return;
    }

    if (_isConnecting) {
      debugPrint('[NotificationService] Ya hay una conexión en progreso, ignorando...');
      return;
    }

    if (_lastDisconnectTime != null) {
      final timeSinceDisconnect = DateTime.now().difference(_lastDisconnectTime!);
      if (timeSinceDisconnect < _minimumReconnectInterval) {
        debugPrint('[NotificationService] Esperando antes de reconectar...');
        _scheduleReconnect();
        return;
      }
    }

    _isConnecting = true;
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
            webSocketConnectHeaders: {
              'Authorization': 'Bearer $_authToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            stompConnectHeaders: {
              'Authorization': 'Bearer $_authToken',
              'login': _userId ?? '',
              'passcode': _authToken ?? '',
              'heart-beat': '10000,10000'
            },
            connectionTimeout: const Duration(seconds: 10)
        )
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _updateConnectionStatus('Conectado');

    final caregiverTopic = '/topic/offers/$_caregiverId';
    final ownerTopic = '/topic/notifications/$_userId';
    final offerAcceptedTopic = '/topic/offers-accepted/$_userId'; // Nuevo tópico
    final offerUnavailableTopic = '/topic/offer-unavailable/$_caregiverId';
    final offerCompletedTopic = '/topic/offer-completed/$_userId';

    debugPrint('[NotificationService] Conectado, suscribiéndose a: $caregiverTopic');
    debugPrint('[NotificationService] Conectado, suscribiéndose a: $ownerTopic');
    debugPrint('[NotificationService] Conectado, suscribiéndose a: $offerAcceptedTopic');
    debugPrint('[NotificationService] Conectado, suscribiéndose a: $offerUnavailableTopic');
    debugPrint('[NotificationService] Conectado, suscribiéndose a: $offerCompletedTopic');

    try {
      // Suscripción para ofertas nuevas (solo cuidadores)
      _stompClient!.subscribe(
          destination: caregiverTopic,
          headers: {
            'Authorization': 'Bearer $_authToken',
            'id': 'sub-$_caregiverId'
          },
          callback: _onOfferReceived
      );

      // Suscripción para ofertas aceptadas (solo dueños)
      _stompClient!.subscribe(
          destination: offerAcceptedTopic,
          headers: {
            'Authorization': 'Bearer $_authToken',
            'id': 'sub-accepted-$_userId'
          },
          callback: _onOfferAcceptedReceived
      );

      // Resto de suscripciones...
      _stompClient!.subscribe(
          destination: ownerTopic,
          headers: {
            'Authorization': 'Bearer $_authToken',
            'id': 'sub-notify-$_userId'
          },
          callback: _onCaregiverNotificationReceived
      );

      // ... otras suscripciones
    } catch (e) {
      debugPrint('[NotificationService] Error en suscripción: $e');
      _handleConnectionError('Error en suscripción');
      return;
    }

    notifyListeners();
  }

  void _handleConnectionError(String errorType) {
    _isConnected = false;
    _isConnecting = false;
    _updateConnectionStatus(errorType);
    if (_shouldReconnect) _scheduleReconnect();
    notifyListeners();
  }

  void _handleDisconnection() {
    _isConnected = false;
    _isConnecting = false;
    _lastDisconnectTime = DateTime.now();
    _updateConnectionStatus('Desconectado');
    if (_shouldReconnect) _scheduleReconnect();
    notifyListeners();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[NotificationService] Máximo de intentos de reconexión alcanzado');
      _shouldReconnect = false;
      _updateConnectionStatus('Conexión fallida');
      return;
    }

    _reconnectTimer?.cancel();
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

  void _onCaregiverNotificationReceived(StompFrame frame) {
    debugPrint('[NotificationService] Mensaje de notificación recibido: ${frame.body}');
    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);
        final messageType = data['type'] as String?;

        if (messageType == 'CAREGIVER_UNAVAILABLE') {
          final caregiverId = data['caregiverId'] as int?;
          if (caregiverId != null) {
            debugPrint('[NotificationService] Cuidador $caregiverId marcado como no disponible');
            _pendingRemovals.add(caregiverId);
            _scheduleBatchUpdate();
          }
        } else if (messageType == 'CAREGIVER_AVAILABLE') {
          final caregiverId = data['caregiverId'] as int?;
          if (caregiverId != null) {
            debugPrint('[NotificationService] Cuidador $caregiverId disponible');
            _pendingUpdates.add(caregiverId);
            _updateCaregiverData(data);
            _scheduleBatchUpdate();
          }
        } else if (messageType == 'OFFER_ACCEPTED') {
          final offerAccepted = OfferAcceptedResponse.fromJson(data);
          debugPrint('[NotificationService] Oferta aceptada: ${offerAccepted.offerId}');
          _onOfferAccepted?.call(offerAccepted);
        } else {
          final caregiverId = data['caregiverId'] as int?;
          if (caregiverId != null) {
            _pendingUpdates.add(caregiverId);
            _updateCaregiverData(data);
            _scheduleBatchUpdate();
          }
        }
      } catch (e) {
        debugPrint('[NotificationService] Error al procesar notificación: $e');
      }
    }
  }

  void _onOfferUnavailableReceived(StompFrame frame) {
    debugPrint('[NotificationService] Mensaje de oferta no disponible recibido: ${frame.body}');
    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);
        final offerUnavailable = OfferUnavailableResponse.fromJson(data);
        debugPrint('[NotificationService] Oferta no disponible: ${offerUnavailable.offerId}');
        _onOfferUnavailable?.call(offerUnavailable);
      } catch (e) {
        debugPrint('[NotificationService] Error al procesar oferta no disponible: $e');
      }
    }
  }

  void _onOfferCompletedReceived(StompFrame frame) {
    debugPrint('[NotificationService] Mensaje de oferta completada recibido: ${frame.body}');
    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);
        final offerCompleted = OfferCompletedResponse.fromJson(data);
        debugPrint('[NotificationService] Oferta completada: ${offerCompleted.offerId}');
        _onOfferCompleted?.call(offerCompleted);
      } catch (e) {
        debugPrint('[NotificationService] Error al procesar oferta completada: $e');
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
          longitude: caregiver.longitude
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
      debugPrint('[NotificationService] ERROR: Frame vacío');
    }
  }

  void _onOfferAcceptedReceived(StompFrame frame) {
    debugPrint('[NotificationService] ¡Mensaje de oferta aceptada recibido!');
    debugPrint('[NotificationService] Contenido del frame: ${frame.body}');
    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);
        debugPrint('[NotificationService] Datos JSON parseados: $data');
        final offerAccepted = OfferAcceptedResponse.fromJson(data);
        debugPrint('[NotificationService] Oferta aceptada: ID=${offerAccepted.offerId}');
        _notificationsAccepted.insert(0, offerAccepted);
        _unreadCount++;
        debugPrint('[NotificationService] Oferta aceptada añadida a la lista. Total no leídas: $_unreadCount');
        notifyListeners();
      } catch (e) {
        debugPrint('[NotificationService] ERROR al procesar la oferta aceptada: $e');
        debugPrint('[NotificationService] Datos del frame: ${frame.body}');
      }
    } else {
      debugPrint('[NotificationService] ERROR: Frame vacío');
    }
  }

  void _updateConnectionStatus(String status) {
    _connectionStatus = status;
    notifyListeners();
  }

  // FUNCIÓN MARK AS READ QUE FALTABA
  void markAsRead() {
    debugPrint('[NotificationService] Marcando todas las notificaciones como leídas');
    _unreadCount = 0;
    notifyListeners();
  }

  // FUNCIÓN CLEAR NOTIFICATIONS QUE FALTABA
  void clearNotifications() {
    debugPrint('[NotificationService] Limpiando todas las notificaciones');
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  void clearAcceptedOffers() {
    debugPrint('[NotificationService] Limpiando todas las ofertas aceptadas');
    _notificationsAccepted.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  // FUNCIÓN ADICIONAL PARA LIMPIAR RECURSOS
  void dispose() {
    _batchUpdateTimer?.cancel();
    _reconnectTimer?.cancel();
    _shouldReconnect = false;
    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
      } catch (e) {
        debugPrint('[NotificationService] Error al desactivar cliente en dispose: $e');
      }
    }
    super.dispose();
  }
}