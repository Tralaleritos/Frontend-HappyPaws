// pet_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/models/pet/species.dart';
import 'package:happyp/data/models/pet/update_pet_request.dart';
import 'package:happyp/data/service/pet_service.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;
  final PetService petService;

  const PetDetailScreen({
    super.key,
    required this.pet,
    required this.petService,
  });

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isDeleting = false;
  late Pet _currentPet;

  // Controllers para los campos de edición
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _imgUrlController = TextEditingController();
  Species _selectedSpecies = Species.DOG;

  @override
  void initState() {
    super.initState();
    _currentPet = widget.pet;
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController.text = _currentPet.name;
    _descriptionController.text = _currentPet.description;
    _breedController.text = _currentPet.breed;
    _ageController.text = _currentPet.age.toString();
    _imgUrlController.text = _currentPet.imgUrl;
    _selectedSpecies = _currentPet.species;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _imgUrlController.dispose();
    super.dispose();
  }

  Future<void> _updatePet() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updateRequest = UpdatePetRequest(
        id: _currentPet.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        species: _selectedSpecies.value,
        breed: _breedController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        imgUrl: _imgUrlController.text.trim(),
      );

      await widget.petService.updatePet(updateRequest);

      // Actualizar el pet local
      setState(() {
        _currentPet = _currentPet.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          species: _selectedSpecies,
          breed: _breedController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          imgUrl: _imgUrlController.text.trim(),
        );
        _isEditing = false;
      });

      _showSnackBar('Mascota actualizada exitosamente', Colors.green);
    } catch (e) {
      debugPrint('Error actualizando mascota: $e');
      _showSnackBar('Error al actualizar la mascota', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePet() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await widget.petService.deletePet(_currentPet.id);

      if (success) {
        _showSnackBar('Mascota eliminada exitosamente', Colors.green);
        Navigator.of(context).pop(true); // Retorna true para indicar que se eliminó
      } else {
        _showSnackBar('Error al eliminar la mascota', Colors.red);
      }
    } catch (e) {
      debugPrint('Error eliminando mascota: $e');
      _showSnackBar('Error al eliminar la mascota', Colors.red);
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('El nombre es requerido', Colors.orange);
      return false;
    }
    if (_breedController.text.trim().isEmpty) {
      _showSnackBar('La raza es requerida', Colors.orange);
      return false;
    }
    if (_ageController.text.trim().isEmpty || int.tryParse(_ageController.text.trim()) == null) {
      _showSnackBar('La edad debe ser un número válido', Colors.orange);
      return false;
    }
    return true;
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar a ${_currentPet.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _initializeControllers(); // Restaurar valores originales
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_currentPet.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          if (!_isEditing && !_isLoading && !_isDeleting)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isEditing && !_isLoading && !_isDeleting)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deletePet,
            ),
        ],
      ),
      body: _isDeleting
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Eliminando mascota...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la mascota
            _buildPetImage(),
            const SizedBox(height: 24),

            // Información básica
            _buildInfoSection(),

            // Botones de acción si está editando
            if (_isEditing) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPetImage() {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(color: AppColors.primary, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(75),
          child: _currentPet.imgUrl.isNotEmpty
              ? Image.network(
            _currentPet.imgUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.pets,
                size: 80,
                color: Colors.grey[600],
              );
            },
          )
              : Icon(
            Icons.pets,
            size: 80,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          _buildInfoField(
            'Nombre',
            _nameController,
            _currentPet.name,
            Icons.pets,
          ),
          const SizedBox(height: 16),

          // Descripción
          _buildInfoField(
            'Descripción',
            _descriptionController,
            _currentPet.description,
            Icons.description,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Especie
          _buildSpeciesField(),
          const SizedBox(height: 16),

          // Raza
          _buildInfoField(
            'Raza',
            _breedController,
            _currentPet.breed,
            Icons.category,
          ),
          const SizedBox(height: 16),

          // Edad
          _buildInfoField(
            'Edad',
            _ageController,
            '${_currentPet.age} años',
            Icons.cake,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // URL de imagen
          if (_isEditing)
            _buildInfoField(
              'URL de imagen',
              _imgUrlController,
              _currentPet.imgUrl,
              Icons.image,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
      String label,
      TextEditingController controller,
      String displayValue,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _isEditing
            ? TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        )
            : Text(
          displayValue,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.pets, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Especie',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _isEditing
            ? DropdownButtonFormField<Species>(
          value: _selectedSpecies,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: Species.values.map((species) {
            return DropdownMenuItem(
              value: species,
              child: Text(_getSpeciesDisplayName(species)),
            );
          }).toList(),
          onChanged: (Species? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSpecies = newValue;
              });
            }
          },
        )
            : Text(
          _getSpeciesDisplayName(_currentPet.species),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getSpeciesDisplayName(Species species) {
    switch (species) {
      case Species.DOG:
        return 'Perro';
      case Species.CAT:
        return 'Gato';
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _cancelEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updatePet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}