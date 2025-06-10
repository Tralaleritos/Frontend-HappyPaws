// Pantalla principal de notificaciones con autenticación
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/models/notification.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';


class NotificationsScreen extends StatefulWidget {
  final int caregiverId;
  final String serverUrl;

  const NotificationsScreen({
    super.key,
    required this.caregiverId,
    required this.serverUrl,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  StompClient? stompClient;
  List<OfferResponse> notifications = [];
  bool isConnected = false;
  String connectionStatus = 'Desconectado';
  String? authToken;
  String? userId;
  List<String> debugLogs = [];

  @override
  void initState() {
    super.initState();
    _addDebugLog('Inicializando NotificationsScreen para caregiver: ${widget.caregiverId}');
    _initializeAuth();
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    setState(() {
      debugLogs.insert(0, '[$timestamp] $message');
      if (debugLogs.length > 20) {
        debugLogs.removeLast();
      }
    });
    print(message);
  }

  void _initializeAuth() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Obtener el token y el ID del usuario
      authToken = await authService.getToken();
      userId = authService.currentUser?.id.toString();

      _addDebugLog('Token obtenido: ${authToken != null ? "Sí" : "No"}');
      _addDebugLog('User ID: $userId');

      if (authToken != null && userId != null) {
        _connectToWebSocket();
      } else {
        setState(() {
          connectionStatus = 'Sin autenticación';
        });
        _addDebugLog('Error: Faltan credenciales de autenticación');
      }
    } catch (e) {
      setState(() {
        connectionStatus = 'Error de autenticación';
      });
      _addDebugLog('Error al obtener autenticación: $e');
    }
  }

  void _connectToWebSocket() {
    if (authToken == null) {
      setState(() {
        connectionStatus = 'Token no disponible';
      });
      return;
    }

    final wsUrl = '${widget.serverUrl}/happy';
    _addDebugLog('Conectando a WebSocket: $wsUrl');

    stompClient = StompClient(
      config: StompConfig.SockJS(
        url: wsUrl,
        onConnect: _onConnect,
        beforeConnect: () async {
          setState(() {
            connectionStatus = 'Conectando...';
          });
          _addDebugLog('Iniciando conexión WebSocket...');
        },
        onWebSocketError: (dynamic error) {
          if (!mounted) return;
          setState(() {
            connectionStatus = 'Error de WebSocket';
            isConnected = false;
          });
          _addDebugLog('Error de WebSocket: $error');
        },
        onStompError: (StompFrame frame) {
          if (!mounted) return;
          setState(() {
            connectionStatus = 'Error STOMP';
            isConnected = false;
          });
          _addDebugLog('Error STOMP: ${frame.body}');
        },
        onDisconnect: (StompFrame frame) {
          if (!mounted) return;
          setState(() {
            connectionStatus = 'Desconectado';
            isConnected = false;
          });
          _addDebugLog('Desconectado del WebSocket');
        },
        // Headers de autenticación
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $authToken',
          'login': userId ?? '',
          'passcode': authToken ?? '',
        },
      ),
    );

    stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    setState(() {
      isConnected = true;
      connectionStatus = 'Conectado';
    });

    final topic = '/topic/offers/${widget.caregiverId}';
    _addDebugLog('Conectado al WebSocket, suscribiéndose a: $topic');

    // Suscribirse al tópico de ofertas para este caregiver
    stompClient!.subscribe(
      destination: topic,
      headers: {
        'Authorization': 'Bearer $authToken',
        'id': 'sub-${widget.caregiverId}',
      },
      callback: _onOfferReceived,
    );

    _addDebugLog('Suscripción completada exitosamente');
  }

  void _onOfferReceived(StompFrame frame) {
    _addDebugLog('¡Mensaje recibido del WebSocket!');
    _addDebugLog('Contenido del frame: ${frame.body}');

    if (frame.body != null) {
      try {
        final Map<String, dynamic> data = json.decode(frame.body!);
        _addDebugLog('Datos JSON parseados: $data');

        final OfferResponse offer = OfferResponse.fromJson(data);
        _addDebugLog('OfferResponse creada: ID=${offer.id}, Descripción=${offer.description}');

        setState(() {
          notifications.insert(0, offer);
        });

        _showNotificationSnackBar(offer);
        _addDebugLog('Notificación añadida a la lista');
      } catch (e) {
        _addDebugLog('ERROR al procesar la notificación: $e');
        _addDebugLog('Datos del frame: ${frame.body}');
      }
    } else {
      _addDebugLog('ERROR: Frame recibido sin contenido');
    }
  }

  void _showNotificationSnackBar(OfferResponse offer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nueva oferta: ${offer.description}'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: () {
            _showOfferDetails(offer);
          },
        ),
      ),
    );
  }

  void _showOfferDetails(OfferResponse offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Oferta #${offer.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Descripción: ${offer.description}'),
                const SizedBox(height: 8),
                Text('Propietario: ${offer.owner.username}'),
                const SizedBox(height: 8),
                Text('Ubicación: ${offer.location.name}'),
                const SizedBox(height: 8),
                Text('Fecha: ${offer.range.date}'),
                Text('Horario: ${offer.range.startTime} - ${offer.range.endTime}'),
                const SizedBox(height: 8),
                if (offer.pets.isNotEmpty) ...[
                  const Text('Mascotas:'),
                  ...offer.pets.map((pet) =>
                      Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text('• ${pet.name} (${pet.type})'),
                      )
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptOffer(offer);
              },
              child: const Text('Aceptar Oferta'),
            ),
          ],
        );
      },
    );
  }

  void _acceptOffer(OfferResponse offer) {
    if (stompClient != null && isConnected && authToken != null) {
      final acceptMessage = {
        'caregiverId': widget.caregiverId,
        'offerId': offer.id,
        'action': 'accept',
        'timestamp': DateTime.now().toIso8601String(),
      };

      stompClient!.send(
        destination: '/app/accept-offer',
        body: json.encode(acceptMessage),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      _addDebugLog('Mensaje de aceptación enviado para oferta ${offer.id}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Oferta #${offer.id} aceptada'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _clearNotifications() {
    setState(() {
      notifications.clear();
    });
  }

  void _clearDebugLogs() {
    setState(() {
      debugLogs.clear();
    });
  }

  void _reconnectWithAuth() {
    _addDebugLog('Reconectando...');
    _initializeAuth();
  }

  @override
  void dispose() {
    stompClient?.deactivate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones de Ofertas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: notifications.isNotEmpty ? _clearNotifications : null,
            tooltip: 'Limpiar notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugDialog(),
            tooltip: 'Ver logs de debug',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estado de conexión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isConnected ? Colors.green.shade100 : Colors.red.shade100,
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connectionStatus,
                        style: TextStyle(
                          color: isConnected ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (authToken != null && userId != null)
                        Text(
                          'Usuario: $userId | Caregiver: ${widget.caregiverId}',
                          style: TextStyle(
                            color: isConnected ? Colors.green.shade600 : Colors.red.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isConnected)
                  TextButton(
                    onPressed: _reconnectWithAuth,
                    child: const Text('Reconectar'),
                  ),
              ],
            ),
          ),

          // Lista de notificaciones
          Expanded(
            child: notifications.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Las nuevas ofertas aparecerán aquí',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final offer = notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${offer.id}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      offer.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Por: ${offer.owner.username}'),
                        Text('${offer.range.date} • ${offer.range.startTime}'),
                        Text('📍 ${offer.location.name}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showOfferDetails(offer),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Debug Logs'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Logs (${debugLogs.length})'),
                    TextButton(
                      onPressed: _clearDebugLogs,
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: debugLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          debugLogs[index],
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}