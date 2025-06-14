import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:happyp/data/models/notification.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

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

  // Getters
  List<OfferResponse> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isConnected => _isConnected;
  String get connectionStatus => _connectionStatus;

  // Inicializar el servicio con los datos necesarios
  void initialize({
    required String authToken,
    required String userId,
    required int caregiverId,
    required String serverUrl,
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

    // Desconectar cliente anterior si existe
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
        onWebSocketError: (dynamic error) {
          _updateConnectionStatus('Error de WebSocket');
          _isConnected = false;
          debugPrint('Error de WebSocket: $error');
          notifyListeners();
        },
        onStompError: (StompFrame frame) {
          _updateConnectionStatus('Error STOMP');
          _isConnected = false;
          debugPrint('Error STOMP: ${frame.body}');
          notifyListeners();
        },
        onDisconnect: (StompFrame frame) {
          _updateConnectionStatus('Desconectado');
          _isConnected = false;
          debugPrint('Desconectado del WebSocket');
          notifyListeners();
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $_authToken',
          'login': _userId ?? '',
          'passcode': _authToken ?? '',
        },
      ),
    );

    _stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _updateConnectionStatus('Conectado');

    final topic = '/topic/offers/$_caregiverId';
    debugPrint('Conectado al WebSocket, suscribiéndose a: $topic');

    _stompClient!.subscribe(
      destination: topic,
      headers: {
        'Authorization': 'Bearer $_authToken',
        'id': 'sub-$_caregiverId',
      },
      callback: _onOfferReceived,
    );

    debugPrint('Suscripción completada exitosamente');
    notifyListeners();
  }

  void _onOfferReceived(StompFrame frame) {
    debugPrint('¡Mensaje recibido del WebSocket!');
    debugPrint('Contenido del frame: ${frame.body}');

    if (frame.body != null) {
      try {
        final Map<String, dynamic> data = json.decode(frame.body!);
        debugPrint('Datos JSON parseados: $data');

        final OfferResponse offer = OfferResponse.fromJson(data);
        debugPrint(
            'OfferResponse creada: ID=${offer.id}, Descripción=${offer.description}');

        _notifications.insert(0, offer);
        _unreadCount++;

        debugPrint(
            'Notificación añadida a la lista. Total no leídas: $_unreadCount');
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

  // Marcar notificaciones como leídas
  void markAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  // Limpiar todas las notificaciones
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  // Aceptar una oferta
  void acceptOffer(OfferResponse offer) {
    if (_stompClient != null &&
        _isConnected &&
        _authToken != null &&
        _caregiverId != null) {
      final acceptMessage = {
        'caregiverId': _caregiverId,
        'offerId': offer.id,
        'action': 'accept',
        'timestamp': DateTime.now().toIso8601String(),
      };

      _stompClient!.send(
        destination: '/app/accept-offer',
        body: json.encode(acceptMessage),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Mensaje de aceptación enviado para oferta ${offer.id}');
    }
  }

  // Reconectar manualmente
  void reconnect() {
    debugPrint('Reconectando...');
    if (_authToken != null &&
        _userId != null &&
        _caregiverId != null &&
        _serverUrl != null) {
      _connectToWebSocket();
    }
  }

  // Cerrar conexión
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
