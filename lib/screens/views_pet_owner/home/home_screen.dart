// home_screen.dart
import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/screens/views_pet_owner/home/controllers/home_controller.dart';
import 'package:happyp/screens/views_pet_owner/home/widgets/pet_section.dart';
import 'package:happyp/screens/views_pet_owner/home/widgets/caregiver_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return ChangeNotifierProvider(
      create: (_) => HomeController(authService),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Panel superior con mascotas
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título de sección
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Text(
                        'Tus mascotas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          // Navegar a la pantalla de notificaciones
                        },
                        icon: const Icon(Icons.notifications_outlined),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Sección de mascotas
                const PetSection(),
              ],
            ),
          ),

          // Header con contador de cuidadores
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Cuidadores cercanos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Consumer<HomeController>(
                  builder: (context, controller, child) {
                    final caregiverCount = controller.nearbyCaregivers.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$caregiverCount disponible${caregiverCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Grid de cuidadores
          Expanded(
            child: Consumer<HomeController>(
              builder: (context, controller, child) {
                final caregivers = controller.nearbyCaregivers;

                if (caregivers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay cuidadores cercanos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Intenta buscar en otra ubicación',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75, // Hace las cards un poco más altas
                  ),
                  itemCount: caregivers.length,
                  itemBuilder: (context, index) {
                    final caregiver = caregivers[index];
                    return CaregiverCard(
                      caregiver: caregiver,
                      onTap: () => controller.selectCaregiver(caregiver),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón de filtros
          FloatingActionButton(
            heroTag: 'filter_button',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: () {
              // Mostrar modal de filtros
            },
            child: const Icon(
              Icons.filter_list,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Botón de ubicación actual
          FloatingActionButton(
            heroTag: 'location_button',
            mini: true,
            backgroundColor: Colors.white,
            onPressed: controller.getCurrentLocation,
            child: const Icon(
              Icons.my_location,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}