import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/caregiver_profile.dart';
import '../../../services/data_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/main_navigation_scaffold_alt.dart'; // IMPORTANTE: asegúrate de importar esto

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
          rating: 4.8,
        );

        bool saved = await _dataService.saveCaregiverProfile(profile);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saved
                ? '¡Tu perfil ha sido guardado correctamente!'
                : 'Hubo un problema al guardar tu perfil. Inténtalo de nuevo.'),
            backgroundColor: saved ? Colors.green : Colors.red,
          ),
        );

        if (saved) {
          _formKey.currentState!.reset();
          nameController.clear();
          specialtyController.clear();
          descriptionController.clear();
          tagsController.clear();
          priceController.clear();
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
    // Mostrar diálogo de confirmación
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmLogout) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/inicio', (_) => false);
      }
    }
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
    return MainNavigationScaffoldAlt(
      currentIndex: 3, // este es el menú actual (Menú)
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
