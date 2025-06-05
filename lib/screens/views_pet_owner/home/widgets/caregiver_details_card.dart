// caregiver_details_card.dart
import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/pet_caregiver.dart';
import 'package:happyp/screens/views_pet_owner/home/controllers/home_controller.dart';
import 'package:provider/provider.dart';

class CaregiverDetailsCard extends StatelessWidget {
  final PetCaregiver caregiver;

  const CaregiverDetailsCard({
    Key? key,
    required this.caregiver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);

    return Container(
        padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 10,
    spreadRadius: 1,
    ),
    ],
    ),
    child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Encabezado con foto y nombre
    Row(
    children: [
    Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.grey.shade200),
    ),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Text(
    caregiver.name,
    style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    ),
    ),
    const SizedBox(width: 6),
    Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: caregiver.isOnline ? Colors.green : Colors.orange,
    ),
    ),
    ],
    ),
    const SizedBox(height: 4),
    Row(
    children: [
    const Icon(
    Icons.star,
    color: Colors.amber,
    size: 16,
    ),
    Text(
    ' ${caregiver.rating}',
    style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    ),
    ),
    Text(
    ' (${caregiver.reviews} reseñas)',
    style: TextStyle(
    fontSize: 12,
    color: Colors.grey.shade600,
    ),
    ),],
    ),
      const SizedBox(height: 4),
      Row(
        children: [
          Icon(
            Icons.location_on,
            color: Colors.grey.shade600,
            size: 16,
          ),
          Text(
            ' A ${caregiver.distance} km de distancia',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    ],
    ),
    ),
      IconButton(
        onPressed: () => controller.toggleFavorite(caregiver),
        icon: Icon(
          controller.favoriteCaregivers.contains(caregiver)
              ? Icons.favorite
              : Icons.favorite_border,
          color: controller.favoriteCaregivers.contains(caregiver)
              ? Colors.red
              : Colors.grey,
        ),
      ),
    ],
    ),

      const SizedBox(height: 12),

      // Especialidades
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: caregiver.specialties.map((specialty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              specialty,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),

      const SizedBox(height: 12),

      // Descripción
      Text(
        caregiver.description,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
        ),
      ),

      const SizedBox(height: 16),

      // Precio
      Row(
        children: [
          const Icon(
            Icons.attach_money,
            color: AppColors.primary,
          ),
          Text(
            ' S/ ${caregiver.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Text(
            ' / hora',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),

      // Botones
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.closeDetails,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.primary),
              ),
              child: const Text('Volver'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Actualizar precio según tipo de servicio seleccionado
                controller.updateServicePrice(
                    caregiver,
                    controller.selectedServiceType
                );
                controller.showServiceRequestForm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Solicitar'),
            ),
          ),
        ],
      ),
    ],
    ),
    );
  }
}