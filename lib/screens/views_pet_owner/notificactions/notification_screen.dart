import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildNotificationCard(context, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, int index) {
    bool isUnread = index < 3; // Primeras 3 son no leídas

    return Container(
      color: isUnread
          ? Theme.of(context).colorScheme.tertiary.withOpacity(0.1)
          : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: index % 2 == 0
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          child: Icon(
            index % 2 == 0 ? Icons.pets : Icons.message,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          index % 2 == 0
              ? 'Nueva solicitud de cuidado'
              : 'Nuevo mensaje recibido',
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          index % 2 == 0
              ? 'Tienes una nueva solicitud de cuidado para revisar'
              : 'María López te ha enviado un mensaje',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Hace ${(index + 1) * 10} min',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}