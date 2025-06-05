// pet_section.dart
import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/pet.dart';
import 'package:happyp/screens/views_pet_owner/home/controllers/home_controller.dart';
import 'package:happyp/screens/views_pet_owner/add_pet/add_pet_screen.dart';
import 'package:provider/provider.dart';

class PetSection extends StatelessWidget {
  const PetSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);

    return SizedBox(
      height: 100,
      child: controller.isLoadingPets
          ? const Center(child: CircularProgressIndicator())
          : controller.userPets.isEmpty
          ? _buildNoPetsMessage(context, controller)
          : ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.userPets.length + 1,
        itemBuilder: (context, index) {
          if (index == controller.userPets.length) {
            return _buildAddPetButton(context, controller);
          } else {
            return _buildPetCard(context, controller.userPets[index]);
          }
        },
      ),
    );
  }

  Widget _buildNoPetsMessage(BuildContext context, HomeController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                color: Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                '¡No tienes mascotas registradas!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: () => _navigateToAddPet(context, controller),
            child: const Text(
              'Agregar una mascota ahora',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPetButton(BuildContext context, HomeController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () => _navigateToAddPet(context, controller),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.add,
                size: 30,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Agregar",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, Pet pet) {
    final controller = Provider.of<HomeController>(context);
    bool isSelected = controller.selectedPet?.id == pet.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: () {
          controller.selectPet(pet);
        },
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.pets,
                    size: 40,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              pet.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddPet(BuildContext context, HomeController controller) async {
    try {
      final ownerId = controller.ownerId;
      if (ownerId == null) {
        debugPrint('[AddPetNavigation] El ID del usuario es null');
        return;
      }

      debugPrint(
          '[AddPetNavigation] Navegando a AddPetScreen con ownerId: $ownerId');

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddPetScreen(ownerId: int.parse(ownerId)),
        ),
      );

      debugPrint(
          '[AddPetNavigation] Resultado al regresar de AddPetScreen: $result');

      if (result == true) {
        debugPrint('[AddPetNavigation] Recargando mascotas...');
        await controller.loadUserPets();
      }
    } catch (e, stack) {
      debugPrint('[AddPetNavigation] Error navegando a AddPetScreen: $e');
      debugPrint('[AddPetNavigation] StackTrace: $stack');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ocurrió un error al intentar agregar la mascota.')),
      );
    }
  }
}