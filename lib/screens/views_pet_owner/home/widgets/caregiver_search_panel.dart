// caregiver_search_panel.dart
import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/screens/views_pet_owner/home/controllers/home_controller.dart';
import 'package:provider/provider.dart';

class CaregiverSearchPanel extends StatelessWidget {
  const CaregiverSearchPanel({Key? key}) : super(key: key);

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
          const Text(
            'Buscar cuidador para:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Tipo de servicio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.selectedServiceType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: <String>[
                  'Paseo',
                  'Visita a domicilio',
                  'Cuidado nocturno',
                  'Entrenamiento',
                  'Veterinaria'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    controller.changeServiceType(newValue);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón de búsqueda
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.userPets.isEmpty
                  ? () => _showAddPetPrompt(context)
                  : controller.startSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Buscar cuidadores',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPetPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.pets, color: AppColors.primary),
            SizedBox(width: 10),
            Flexible( // Envuelve el Text con Flexible
              child: Text('Agrega una mascota primero'),
            ),
          ],
        ),
        content: const Text(
          'Para buscar cuidadores, necesitas registrar al menos una mascota en tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Después',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegación a la pantalla de agregar mascota
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Agregar mascota'),
          ),
        ],
      ),
    );
  }
}
