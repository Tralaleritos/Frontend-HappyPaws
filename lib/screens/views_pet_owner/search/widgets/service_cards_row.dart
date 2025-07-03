import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/offers/offer.dart'; // ← Asegúrate que aquí está ServiceType

class ServiceCardsRow extends StatelessWidget {
  final List<ServiceType> services;
  final String selectedService;
  final Function(String) onServiceSelected;
  final Function(String) onAddPetPressed;

  const ServiceCardsRow({
    super.key,
    required this.services,
    required this.selectedService,
    required this.onServiceSelected,
    required this.onAddPetPressed,
  });

  IconData _getIcon(String serviceName) {
    final map = {
      'Paseo': Icons.directions_walk,
      'Veterinario': Icons.local_hospital,
      'Peluquería': Icons.content_cut,
      'Hospedaje': Icons.hotel,
      'Entrenamiento': Icons.sports,
      'Guardería': Icons.child_care,
      'Alimentación': Icons.fastfood,
      'Cuidado': Icons.volunteer_activism,
    };

    return map[serviceName] ?? Icons.miscellaneous_services;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Servicios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (selectedService.isNotEmpty)
                TextButton(
                  onPressed: () => onServiceSelected(''),
                  child: const Text('Ver todos'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(context, service);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceType service) {
    final bool isSelected = selectedService == service.name;

    return GestureDetector(
      onTap: () => onServiceSelected(service.name),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
              : Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
              color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIcon(service.name),
                  size: 40,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  service.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : null,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 28,
                ),
                onPressed: () => onAddPetPressed(service.name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
