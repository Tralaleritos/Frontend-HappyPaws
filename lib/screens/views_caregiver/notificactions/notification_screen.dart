// notification_screen.dart - Versión actualizada que usa el servicio global
import 'package:flutter/material.dart';
import 'package:happyp/data/service/notification_service.dart';
import 'package:happyp/data/service/offer_service.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/models/offers/accept_offer.dart';
import '../../../data/models/notifications/offer_response.dart';

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
  final NotificationService _notificationService = NotificationService();
  final OfferService _offerService = OfferService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Configurar el token del servicio de ofertas
    _setupOfferService();
    // Marcar como leídas al entrar a la pantalla
    _notificationService.markAsRead();
    // Escuchar cambios en el servicio
    _notificationService.addListener(_onNotificationServiceChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationServiceChanged);
    super.dispose();
  }

  void _onNotificationServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Método para configurar el token en el servicio de ofertas
  Future<void> _setupOfferService() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        _offerService.setAuthToken(token);
        print('Token configurado en OfferService');
      } else {
        print('No se encontró token de autenticación');
      }
    } catch (e) {
      print('Error al configurar token: $e');
    }
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
                Text('Precio: ${offer.price}'),
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

  void _acceptOffer(OfferResponse offer) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Aceptando oferta...'),
              ],
            ),
          );
        },
      );

      // Crear la request para aceptar la oferta
      final acceptRequest = AcceptOfferRequest(
        offerId: offer.id,
        caregiverId: widget.caregiverId,
      );

      // Llamar al servicio para aceptar la oferta
      await _offerService.acceptOffer(acceptRequest);

      // Cerrar el diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oferta #${offer.id} aceptada exitosamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Opcional: Remover la notificación de la lista local
      // _notificationService.removeNotification(offer.id);

    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aceptar oferta: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Opcional: Mostrar diálogo de error más detallado
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('No se pudo aceptar la oferta #${offer.id}.\n\nDetalle: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _acceptOffer(offer); // Reintentar
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Estado de Conexión'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado: ${_notificationService.connectionStatus}'),
                const SizedBox(height: 8),
                Text('Conectado: ${_notificationService.isConnected ? "Sí" : "No"}'),
                const SizedBox(height: 8),
                Text('Total notificaciones: ${_notificationService.notifications.length}'),
                const SizedBox(height: 8),
                Text('No leídas: ${_notificationService.unreadCount}'),
                const SizedBox(height: 16),
                if (!_notificationService.isConnected)
                  ElevatedButton(
                    onPressed: () {
                      _notificationService.reconnect();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Reconectar'),
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

  @override
  Widget build(BuildContext context) {
    final notifications = _notificationService.notifications;
    final isConnected = _notificationService.isConnected;
    final connectionStatus = _notificationService.connectionStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones de Ofertas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: notifications.isNotEmpty
                ? _notificationService.clearNotifications
                : null,
            tooltip: 'Limpiar notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDebugDialog,
            tooltip: 'Estado de conexión',
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
                      Text(
                        'Caregiver: ${widget.caregiverId} | Total: ${notifications.length}',
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
                    onPressed: _notificationService.reconnect,
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
}