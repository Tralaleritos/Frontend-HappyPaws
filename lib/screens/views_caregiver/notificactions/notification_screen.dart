// notification_screen.dart - Versión actualizada que usa el servicio global
import 'package:flutter/material.dart';
import 'package:happyp/data/models/notification.dart';
import 'package:happyp/data/service/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
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
    _notificationService.acceptOffer(offer);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Oferta #${offer.id} aceptada'),
        backgroundColor: Colors.blue,
      ),
    );
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