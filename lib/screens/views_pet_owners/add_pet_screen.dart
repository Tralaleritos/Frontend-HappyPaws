// lib/screens/pets/add_pet_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pet.dart';
import '../../../services/pet_service.dart';
import '../../../services/auth_service.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specieController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSaving = false;

  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final pet = Pet(
        name: _nameController.text,
        specie: _specieController.text,
        breed: _breedController.text,
        age: int.parse(_ageController.text),
        description: _descriptionController.text,
      );

      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null || currentUser.role != 'pet_owner') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solo los dueños de mascotas pueden guardar mascotas.')),
        );
        return;
      }

      await PetService().savePet(currentUser.email, pet);

      if (!mounted) return;
      Navigator.pop(context, true); // puedes usar true para indicar éxito
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specieController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Mascota')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _specieController,
                decoration: const InputDecoration(labelText: 'Especie'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Raza'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Edad'),
                validator: (value) =>
                value!.isEmpty || int.tryParse(value) == null ? 'Edad inválida' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _savePet,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Guardar Mascota'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
