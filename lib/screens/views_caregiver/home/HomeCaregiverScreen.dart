import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:happyp/data/models/pet.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class HomeCaregiverScreen extends StatefulWidget {
  const HomeCaregiverScreen({super.key});

  @override
  State<HomeCaregiverScreen> createState() => _HomeCaregiverScreenState();
}

class _HomeCaregiverScreenState extends State<HomeCaregiverScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final petService = Provider.of<PetService>(context, listen: false);
      final userService = UserService();

      await authService.fetchAndSetUserId(userService);
      petService.setAuthToken(await authService.getToken() ?? '');

      final pets = await petService.getUserPets();

      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar mascotas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido Cuidador'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '¡Hola, ${user?.username ?? 'cuidador'}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Mascotas asignadas:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(pet.name[0].toUpperCase()),
                    ),
                    title: Text(pet.name),
                    subtitle: Text('${pet.breed}, ${pet.age} años'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
