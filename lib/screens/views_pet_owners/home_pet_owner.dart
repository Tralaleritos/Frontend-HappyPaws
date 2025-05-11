// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happyp/screens/views_pet_owners/add_pet_screen.dart';
import '../../../models/pet.dart';
import '../../../widgets/main_navigation_scaffold.dart';
import '../../../services/auth_service.dart';

class HomePetOwner extends StatefulWidget {
  const HomePetOwner({super.key});

  @override
  State<HomePetOwner> createState() => _HomePetOwnerState();
}

class _HomePetOwnerState extends State<HomePetOwner> {
  final List<Pet> _pets = [];

  void _navigateToAddPet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );

    if (result != null && result is Pet) {
      setState(() {
        _pets.add(result);
      });
    }
  }

  Future<void> _logout() async {
    // Mostrar diálogo de confirmación
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
      canPop: false, // Impedir el comportamiento normal de retroceso
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _logout();
      },
      child: MainNavigationScaffold(
        currentIndex: 0,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Eliminar el botón back por defecto
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
              onPressed: _logout,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeBanner(context),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _navigateToAddPet,
                icon: const Icon(Icons.add),
                label: const Text('Add Pet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              _buildPetsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gestiona a tus mascotas y encuentra los mejores servicios',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return Expanded(
      child: _pets.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No has agregado mascotas todavía',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón "Add Pet" arriba para comenzar',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _pets.length,
        itemBuilder: (context, index) {
          final pet = _pets[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // Navegar al detalle de la mascota
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Detalles de ${pet.name}')),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Icon(
                        _getPetIcon(pet.specie),
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pet.specie} • ${pet.breed}',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Edad: ${pet.age} ${_getAgeUnit(pet.age)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        _showPetOptions(context, pet);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getPetIcon(String specie) {
    switch (specie.toLowerCase()) {
      case 'dog':
      case 'perro':
        return Icons.pets;
      case 'cat':
      case 'gato':
        return Icons.sentiment_satisfied_alt;
      case 'bird':
      case 'ave':
        return Icons.flutter_dash;
      default:
        return Icons.pets;
    }
  }

  String _getAgeUnit(int age) {
    return age == 1 ? 'año' : 'años';
  }

  void _showPetOptions(BuildContext context, Pet pet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Editar ${pet.name}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Historial Médico'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Historial médico de ${pet.name}')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Eliminar'),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePet(pet);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePet(Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar a ${pet.name}?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _pets.remove(pet);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${pet.name} ha sido eliminado')),
              );
            },
            child: const Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}