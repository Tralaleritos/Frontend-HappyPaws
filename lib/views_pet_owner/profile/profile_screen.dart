import 'package:flutter/material.dart';
import '../../widgets/main_navigation_scaffold.dart'; // Ajusta esta ruta si es necesario

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainNavigationScaffold(
      currentIndex: 3,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
              child: Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: const Text(
                        'JP',
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Juan Pérez',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Ciudad de México',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Editar Perfil'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mis Mascotas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          'Añadir',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPetCard(context, 'Max', 'Perro', 'Labrador'),
                        _buildPetCard(context, 'Luna', 'Gato', 'Siamés'),
                        _buildPetCard(context, 'Rocky', 'Perro', 'Bulldog'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Próximas Citas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(
                    context,
                    'Paseo con Max',
                    'María López',
                    'Mañana, 3:00 PM',
                  ),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(
                    context,
                    'Veterinario para Luna',
                    'Dr. García',
                    'Viernes, 10:00 AM',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Historial de Servicios',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildServiceHistoryCard(
                    context,
                    'Peluquería para Max',
                    'Ana Gómez',
                    'Hace 2 días',
                  ),
                  const SizedBox(height: 16),
                  _buildServiceHistoryCard(
                    context,
                    'Paseo con Rocky',
                    'Carlos Rodríguez',
                    'Hace 1 semana',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, String name, String type, String breed) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              type == 'Perro' ? Icons.pets : Icons.face,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            breed,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, String title, String provider, String time) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    provider,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Confirmado',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHistoryCard(BuildContext context, String service, String provider, String time) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
              child: Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(provider, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
