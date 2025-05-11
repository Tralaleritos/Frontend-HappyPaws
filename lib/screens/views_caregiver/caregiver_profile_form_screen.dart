import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/caregiver_profile.dart';
import '../../../services/data_service.dart';
import '../../../services/auth_service.dart';

class CaregiverProfileFormScreen extends StatefulWidget {
  const CaregiverProfileFormScreen({super.key});

  @override
  State<CaregiverProfileFormScreen> createState() => _CaregiverProfileFormScreenState();
}

class _CaregiverProfileFormScreenState extends State<CaregiverProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final specialtyController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final tagsController = TextEditingController();
  bool _isSaving = false;
  final _dataService = DataService();

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final profile = CaregiverProfile(
          name: nameController.text,
          specialty: specialtyController.text,
          description: descriptionController.text,
          tags: tagsController.text.split(',').map((e) => e.trim()).toList(),
          price: double.parse(priceController.text),
          rating: 4.8, // default
        );

        bool saved = await _dataService.saveCaregiverProfile(profile);

        if (!mounted) return;

        if (saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Tu perfil ha sido guardado correctamente!'),
              backgroundColor: Colors.green,
            ),
          );

          _formKey.currentState!.reset();
          nameController.clear();
          specialtyController.clear();
          descriptionController.clear();
          tagsController.clear();
          priceController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hubo un problema al guardar tu perfil. Inténtalo de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/inicio', (route) => false);
  }

  @override
  void dispose() {
    nameController.dispose();
    specialtyController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear perfil de cuidador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: specialtyController,
                decoration: const InputDecoration(labelText: 'Especialidad (ej. Paseador)'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción del servicio'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiquetas (ej. Paseos, Juegos)',
                  hintText: 'Separa las etiquetas con comas',
                ),
                validator: (v) => v!.isEmpty ? 'Ingresa al menos una etiqueta' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Precio por hora'),
                validator: (v) => v == null || double.tryParse(v) == null ? 'Precio inválido' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSaving
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Guardando...'),
                  ],
                )
                    : const Text('Guardar perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
