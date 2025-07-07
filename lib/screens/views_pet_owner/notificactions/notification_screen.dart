// notification_screen.dart - Versión actualizada que recibe ofertas aceptadas
import 'package:flutter/material.dart';
import 'package:happyp/data/models/offers/offer_accept_response.dart';
import 'package:happyp/data/service/notification_service.dart';

import '../payment/payment_screen.dart';

class NotificationScreen extends StatefulWidget {
  final int ownerId;
  final String serverUrl;

  const NotificationScreen({
    super.key,
    required this.ownerId,
    required this.serverUrl,
  });

  @override
  State<NotificationScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  // Lista para almacenar las notificaciones de ofertas aceptadas
  final List<OfferAcceptedResponse> _acceptedOffers = [];

  @override
  void initState() {
    super.initState();
    // Marcar como leídas al entrar a la pantalla
    _notificationService.markAsRead();
    // Escuchar cambios en el servicio
    _notificationService.addListener(_onNotificationServiceChanged);

    // Configurar el callback para ofertas aceptadas
    _notificationService.setOnOfferAccepted(_onOfferAcceptedReceived);
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

  // Callback para manejar ofertas aceptadas
  void _onOfferAcceptedReceived(OfferAcceptedResponse acceptedOffer) {
    if (mounted) {
      setState(() {
        _acceptedOffers.insert(0, acceptedOffer);
      });

      // Mostrar un snackbar para notificar al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Oferta #${acceptedOffer.offerId}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () => _showOfferAcceptedDetails(acceptedOffer),
          ),
        ),
      );
    }
  }

  void _showOfferDetails(OfferAcceptedResponse offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Oferta #${offer.offerId}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Descripción: ${offer.caregiverName}'),
                const SizedBox(height: 8),
                Text('Por: ${offer.offerId}'),
                const SizedBox(height: 8),
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

  void _showOfferAcceptedDetails(OfferAcceptedResponse acceptedOffer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Oferta Aceptada #${acceptedOffer.offerId}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text('Cuidador: ${acceptedOffer.caregiverName}'),
                const SizedBox(height: 8),
                Text('ID del cuidador: ${acceptedOffer.caregiverId}'),
                const SizedBox(height: 8),
                Image.network(acceptedOffer.caregiverImgUrl, height: 80),
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


  void _clearAcceptedOffers() {
    setState(() {
      _acceptedOffers.clear();
    });
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
                const SizedBox(height: 8),
                Text('Ofertas aceptadas: ${_acceptedOffers.length}'),
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
    final notifications = _notificationService.notificationsAccepted;
    final isConnected = _notificationService.isConnected;
    final connectionStatus = _notificationService.connectionStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ofertas Aceptadas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: notifications.isNotEmpty
                ? _notificationService.clearAcceptedOffers
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
                        'Owner: ${widget.ownerId} | Total: ${notifications.length}',
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
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PaymentScreen(), // Asegúrate de importar
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '${offer.offerId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      offer.caregiverImgUrl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Contacto: ${offer.caregiverName}'),
                        const SizedBox(height: 4),
                        const Text(
                          '💰 Tienes que pagar el 50% del pago antes del día del servicio.',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
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