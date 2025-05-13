import 'package:flutter/material.dart';
import '../../widgets/main_navigation_scaffold.dart'; // Asegúrate de que la ruta es correcta

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainNavigationScaffold(
      currentIndex: 2, // Estás en la sección "Mensajes"
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return _buildMessageCard(context);
        },
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Text(
          'M',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        'María López',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        'Hola, ¿a qué hora puedo pasar por tu mascota?',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '10:30 AM',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Text(
              '2',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
