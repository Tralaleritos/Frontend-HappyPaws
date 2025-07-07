// caregiver_map_widget.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:happyp/screens/views_pet_owner/home/controllers/home_controller.dart';
import 'package:provider/provider.dart';

class CaregiverMapWidget extends StatelessWidget {
  const CaregiverMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final caregivers = controller.nearbyCaregivers;

        if (caregivers.isEmpty) {
          return _buildEmptyState();
        }

        return _buildMapView(controller);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(
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
      ),
    );
  }

  Widget _buildMapView(HomeController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          onMapCreated: (GoogleMapController mapController) {
            if (!controller.mapController.isCompleted) {
              controller.mapController.complete(mapController);
            }
          },
          initialCameraPosition: controller.initialCameraPosition,
          markers: controller.allMarkers,
          circles: controller.circles,
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          onTap: (LatLng position) {
            // Deseleccionar cuidador si se toca el mapa
            controller.selectCaregiver(null);
          },
        ),
      ),
    );
  }
}