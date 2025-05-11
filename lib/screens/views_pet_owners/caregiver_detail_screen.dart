import 'package:flutter/material.dart';
import '../../../models/caregiver_profile.dart';
import '../../../models/pet.dart';
import '../../../services/request_service.dart';
import 'request_form_screen.dart';

class CaregiverDetailScreen extends StatelessWidget {
  final CaregiverProfile caregiver;

  const CaregiverDetailScreen({super.key, required this.caregiver});

  Future<bool> _hasRequest(String name) async {
    return await RequestService().hasSentRequest(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Cuidador'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                caregiver.name.isNotEmpty ? caregiver.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              caregiver.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              caregiver.specialty,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Vista detallada del perfil, si la tienes
              },
              child: const Text('Ver Perfil'),
            ),
            const SizedBox(height: 16),
            Text(
              caregiver.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildInfoRow(context, Icons.attach_money, 'Precio', 'S/ ${caregiver.price} / h'),
            _buildInfoRow(context, Icons.location_on, 'Ubicación', 'San Miguel'),
            _buildInfoRow(context, Icons.access_time, 'Disponibilidad', 'Ahora'),

            const Spacer(),
            FutureBuilder<bool>(
              future: _hasRequest(caregiver.name),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final hasRequested = snapshot.data!;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    hasRequested
                        ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Solicitud Enviada'),
                    )
                        : ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestFormScreen(
                              pet: Pet(
                                name: 'Michifus',
                                specie: 'Gato',
                                breed: 'Siamés',
                                age: 2,
                                description: 'Ejemplo de mascota',
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.pets),
                      label: const Text('Solicitar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Acción para contactar
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Contactar'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

}
