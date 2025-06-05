// screens/add_pet_screen.dart
import 'package:flutter/material.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/pet.dart';
import 'package:happyp/screens/views_pet_owner/add_pet/controllers/add_pet_controller.dart';

class AddPetScreen extends StatelessWidget {
  final int ownerId;

  const AddPetScreen({Key? key, required this.ownerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    return ChangeNotifierProvider(
      create: (_) => AddPetController(authService),
      child: _AddPetView(ownerId: ownerId),
    );
  }
}

class _AddPetView extends StatelessWidget {
  final int ownerId;

  const _AddPetView({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Agregar Mascota',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AddPetController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar de mascota
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Icon(
                      Icons.pets,
                      size: 60,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Campo de nombre
                _buildInputField(
                  'Nombre de la mascota',
                  controller.nameController,
                  Icons.pets,
                  'Ej: Max, Luna, Buho',
                ),
                const SizedBox(height: 20),

                // Campo de descripción
                _buildInputField(
                  'Descripción',
                  controller.descriptionController,
                  Icons.description,
                  'Cuéntanos sobre tu mascota...',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Selector de especie
                _buildSectionTitle('Tipo de mascota'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpeciesOption(
                        context,
                        controller,
                        Species.DOG,
                        'Perro',
                        Icons.pets,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildSpeciesOption(
                        context,
                        controller,
                        Species.CAT,
                        'Gato',
                        Icons.pets,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Campo de raza
                _buildSectionTitle('Raza'),
                const SizedBox(height: 10),
                _buildBreedDropdown(controller),
                const SizedBox(height: 20),

                // Campo de edad
                _buildInputField(
                  'Edad (años)',
                  controller.ageController,
                  Icons.cake,
                  'Ej: 3',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Mensaje de error
                if (controller.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Botón de guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading
                        ? null
                        : () => _handleCreatePet(context, controller),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Agregar Mascota',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      IconData icon,
      String hint, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(icon, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesOption(
      BuildContext context,
      AddPetController controller,
      Species species,
      String label,
      IconData icon,
      ) {
    final isSelected = controller.selectedSpecies == species;

    return GestureDetector(
      onTap: () => controller.setSpecies(species),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedDropdown(AddPetController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.category, color: AppColors.primary),
        ),
        hint: Text(
          'Selecciona una raza',
          style: TextStyle(color: Colors.grey.shade500),
        ),
        value: controller.breedController.text.isEmpty ? null : controller.breedController.text,
        items: controller.availableBreeds.map((breed) {
          return DropdownMenuItem<String>(
            value: breed,
            child: Text(breed),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.breedController.text = value;
          }
        },
      ),
    );
  }

  Future<void> _handleCreatePet(BuildContext context, AddPetController controller) async {
    controller.clearError();

    final success = await controller.createPet(ownerId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Mascota agregada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Retornar true para indicar que se agregó una mascota
    }
  }
}