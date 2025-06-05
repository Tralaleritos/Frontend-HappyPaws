// home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/screens/views_pet_owner/home/controllers/home_controller.dart';
import 'package:happyp/screens/views_pet_owner/home/widgets/caregiver_details_card.dart';
import 'package:happyp/screens/views_pet_owner/home/widgets/caregiver_search_panel.dart';
import 'package:happyp/screens/views_pet_owner/home/widgets/pet_section.dart';
import 'package:happyp/screens/views_pet_owner/home/widgets/search_animation.dart';
import 'package:happyp/screens/views_pet_owner/home/widgets/service_request_form.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
  const _HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Mapa como fondo
          GoogleMap(
            initialCameraPosition: HomeController.initialCameraPosition,
            mapType: MapType.normal,
            markers: controller.markers,
            circles: controller.circles,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            onMapCreated: (GoogleMapController mapController) {
              controller.mapController.complete(mapController);
            },
          ),

          // Botón de ubicación actual
          Positioned(
            bottom: 160,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location_button',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: controller.getCurrentLocation,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
              ),
            ),
          ),

          // Botón de filtros
          Positioned(
            bottom: 210,
            right: 16,
            child: FloatingActionButton(
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
          ),

          // Panel superior con mascotas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
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
          ),

          // Panel inferior con opciones de búsqueda
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Resultados si hay cuidadores visibles
                if (controller.visibleCaregivers.isNotEmpty &&
                    !controller.isSearching &&
                    !controller.showCaregiverDetails &&
                    !controller.showServiceForm)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded( // <-- Ajusta automáticamente al espacio restante
                            child: Text(
                              'Encontramos ${controller.visibleCaregivers.length} cuidadores',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis, // Opcional: para cortar si aún se pasa
                            ),
                          ),
                          TextButton(
                            onPressed: controller.startSearch,
                            child: const Text('Buscar de nuevo'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Panel de búsqueda, animación o detalles
                if (controller.isSearching)
                  SearchAnimation(
                    serviceType: controller.selectedServiceType,
                  )
                else if (controller.showCaregiverDetails &&
                    controller.selectedCaregiver != null)
                  CaregiverDetailsCard(
                    caregiver: controller.selectedCaregiver!,
                  )
                else if (controller.showServiceForm)
                    const ServiceRequestForm()
                  else
                    const CaregiverSearchPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}