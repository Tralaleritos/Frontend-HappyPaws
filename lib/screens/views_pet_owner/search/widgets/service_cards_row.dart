import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class ServiceCardsRow extends StatelessWidget {
  final String selectedService;
  final Function(String) onServiceSelected;
  final Function(String) onAddPetPressed;

  const ServiceCardsRow({
    super.key,
    required this.selectedService,
    required this.onServiceSelected,
    required this.onAddPetPressed,
  });

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
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildServiceCard(context, 'Paseo', Icons.directions_walk),
              _buildServiceCard(context, 'Veterinario', Icons.local_hospital),
              _buildServiceCard(context, 'Peluquería', Icons.content_cut),
              _buildServiceCard(context, 'Hospedaje', Icons.hotel),
              _buildServiceCard(context, 'Entrenamiento', Icons.sports),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon) {
    final bool isSelected = selectedService == title;

    return GestureDetector(
      onTap: () => onServiceSelected(title),
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
                  icon,
                  size: 40,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
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
                onPressed: () => onAddPetPressed(title),
              ),
            ),
          ],
        ),
      ),
    );
  }
}