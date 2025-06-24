import 'dart:convert';
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
    debugPrint('Conectando a WebSocket: $wsUrl');

    _stompClient = StompClient(
        config: StompConfig.SockJS(
            url: wsUrl,
            onConnect: _onConnect,
            beforeConnect: () async {
              _updateConnectionStatus('Conectando...');
              debugPrint('Iniciando conexión WebSocket...');
            },
            onWebSocketError: (error) {
              _updateConnectionStatus('Error de WebSocket');
              _isConnected = false;
              debugPrint('Error de WebSocket: $error');
              notifyListeners();
            },
            onStompError: (frame) {
              _updateConnectionStatus('Error STOMP');
              _isConnected = false;
              debugPrint('Error STOMP: ${frame.body}');
              notifyListeners();
            },
            onDisconnect: (frame) {
              _updateConnectionStatus('Desconectado');
              _isConnected = false;
              debugPrint('Desconectado del WebSocket');
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
    _updateConnectionStatus('Conectado');

    final caregiverTopic = '/topic/offers/$_caregiverId';
    final ownerTopic = '/topic/notifications/$_userId';

    debugPrint('Conectado al WebSocket, suscribiéndose a: $caregiverTopic');
    debugPrint('Conectado al WebSocket, suscribiéndose a: $ownerTopic');

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

    debugPrint('Suscripción completada exitosamente');
    notifyListeners();
  }

  void _onCaregiverNotificationReceived(StompFrame frame) {
    debugPrint('Mensaje de notificación recibido: ${frame.body}');
    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);

        // Verificar si es un mensaje de cuidador no disponible
        if (data['type'] == 'CAREGIVER_UNAVAILABLE') {
          final caregiverId = data['caregiverId'];
          _removeCaregiverFromList(caregiverId);
          debugPrint('Cuidador $caregiverId removido de la lista por no disponibilidad');
        } else if (data['type'] == 'CAREGIVER_AVAILABLE') {
          // Es un cuidador disponible (mensaje normal)
          final caregiver = CaregiversNearbyResponse.fromJson(data);
          debugPrint('Cuidador parseado: $caregiver');

          // Verificar si el cuidador ya existe en la lista para evitar duplicados
          // Usar caregiverId del JSON en lugar del id del objeto parseado
          final caregiverId = data['caregiverId'];
          final existingIndex = _nearbyCaregivers.indexWhere((c) => c.id == caregiverId);

          if (existingIndex == -1) {
            // Crear una nueva instancia con el ID correcto
            final updatedCaregiver = CaregiversNearbyResponse(
              id: caregiverId,
              userName: caregiver.userName,
              imgUrl: caregiver.imgUrl,
              latitude: caregiver.latitude,
              longitude: caregiver.longitude,
            );
            _nearbyCaregivers.insert(0, updatedCaregiver);
            debugPrint('Nuevo cuidador agregado: ${updatedCaregiver.userName} (ID: $caregiverId)');
          } else {
            // Actualizar la información del cuidador existente
            final updatedCaregiver = CaregiversNearbyResponse(
              id: caregiverId,
              userName: caregiver.userName,
              imgUrl: caregiver.imgUrl,
              latitude: caregiver.latitude,
              longitude: caregiver.longitude,
            );
            _nearbyCaregivers[existingIndex] = updatedCaregiver;
            debugPrint('Cuidador actualizado: ${updatedCaregiver.userName} (ID: $caregiverId)');
          }
        }

        notifyListeners();
      } catch (e) {
        debugPrint('Error al procesar notificación de cuidador: $e');
      }
    }
  }

  void _removeCaregiverFromList(int caregiverId) {
    final initialLength = _nearbyCaregivers.length;
    _nearbyCaregivers.removeWhere((caregiver) => caregiver.id == caregiverId);
    final removedCount = initialLength - _nearbyCaregivers.length;

    if (removedCount > 0) {
      debugPrint('Removidos $removedCount cuidador(es) con ID: $caregiverId');
    } else {
      debugPrint('No se encontró cuidador con ID: $caregiverId para remover');
    }
  }

  void _onOfferReceived(StompFrame frame) {
    debugPrint('¡Mensaje recibido del WebSocket!');
    debugPrint('Contenido del frame: ${frame.body}');

    if (frame.body != null) {
      try {
        final data = json.decode(frame.body!);
        debugPrint('Datos JSON parseados: $data');

        final offer = OfferResponse.fromJson(data);
        debugPrint('OfferResponse creada: ID=${offer.id}, Descripción=${offer.description}');

        _notifications.insert(0, offer);
        _unreadCount++;

        debugPrint('Notificación añadida a la lista. Total no leídas: $_unreadCount');
        notifyListeners();
      } catch (e) {
        debugPrint('ERROR al procesar la notificación: $e');
        debugPrint('Datos del frame: ${frame.body}');
      }
    } else {
      debugPrint('ERROR: Frame recibido sin contenido');
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

      debugPrint('Mensaje de aceptación enviado para oferta ${offer.id}');
    }
  }

  void reconnect() {
    debugPrint('Reconectando...');
    if (_authToken != null && _userId != null && _caregiverId != null && _serverUrl != null) {
      _connectToWebSocket();
    }
  }

  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
    _updateConnectionStatus('Desconectado');
    debugPrint('Servicio de notificaciones desconectado');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}