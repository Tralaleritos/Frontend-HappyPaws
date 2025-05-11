import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_navigation_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Maneja el botón físico de atrás del dispositivo
  Future<void> _handleLogout(BuildContext context) async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmLogout) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/inicio', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Impedimos el comportamiento normal de retroceso
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _handleLogout(context);
      },
      child: MainNavigationScaffold(
        currentIndex: 0,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Eliminamos el botón back por defecto
          title: const Text('Happy Paws'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeBanner(context),
            const SizedBox(height: 24),
            _buildServicesSection(context),
            const SizedBox(height: 24),
            _buildCaregiversSection(context),
          ],
        ),
      ),
    );
  }

  // Banner de bienvenida con gradiente
  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Bienvenido!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Encuentra los mejores cuidadores para tu mascota',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/search');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Explorar ahora'),
            ),
          ],
        ),
      ),
    );
  }

  // Sección de servicios
  Widget _buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Servicios', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryCard(context, 'Paseo', Icons.directions_walk),
              _buildCategoryCard(context, 'Veterinario', Icons.local_hospital),
              _buildCategoryCard(context, 'Peluquería', Icons.content_cut),
              _buildCategoryCard(context, 'Hospedaje', Icons.hotel),
              _buildCategoryCard(context, 'Entrenamiento', Icons.sports),
            ],
          ),
        ),
      ],
    );
  }

  // Sección de cuidadores
  Widget _buildCaregiversSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuidadores destacados', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        _buildCaregiverCard(context, 'María López', 'Paseadora de perros', '4.9'),
        const SizedBox(height: 16),
        _buildCaregiverCard(context, 'Juan Pérez', 'Veterinario a domicilio', '4.8'),
        const SizedBox(height: 16),
        _buildCaregiverCard(context, 'Ana García', 'Peluquería canina', '4.7'),
      ],
    );
  }

  // Tarjeta para categoría de servicio
  Widget _buildCategoryCard(BuildContext context, String title, IconData icon) {
    return InkWell(
      onTap: () {
        // Navegar a la página de la categoría cuando se toque
        Navigator.pushNamed(context, '/services', arguments: {'category': title});
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta para cuidador
  Widget _buildCaregiverCard(BuildContext context, String name, String speciality, String rating) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegar al perfil del cuidador cuando se toque la tarjeta
          Navigator.pushNamed(context, '/caregiver-profile', arguments: {'name': name});
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  name.substring(0, 1),
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                    Text(speciality, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Acción para contactar al cuidador
                  Navigator.pushNamed(context, '/contact', arguments: {'caregiverName': name});
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Contactar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}