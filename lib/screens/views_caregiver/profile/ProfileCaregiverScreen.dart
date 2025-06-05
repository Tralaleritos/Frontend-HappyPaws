import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/nueva/user_model.dart';

class ProfileCaregiverScreen extends StatefulWidget {
  const ProfileCaregiverScreen({super.key});

  @override
  State<ProfileCaregiverScreen> createState() => _ProfileCaregiverScreenState();
}

class _ProfileCaregiverScreenState extends State<ProfileCaregiverScreen> {
  // Datos de ejemplo para el cuidador
  final String name = "Alexis";
  final String location = "San Miguel, Perú";
  final String bio = "Cuidadora profesional con 5 años de experiencia. Amante de los perros y especialista en adiestramiento básico. Ofrezco paseos diarios, cuidados especiales y mucho cariño para tu mascota.";
  final List<String> interests = ["Paseos", "Adiestramiento", "Cuidados especiales", "Perros grandes"];

  // Datos de disponibilidad (ejemplo)
  final Map<String, List<String>> availability = {
    "Lunes": ["9:00 - 13:00", "16:00 - 19:00"],
    "Martes": ["9:00 - 13:00", "16:00 - 19:00"],
    "Miércoles": ["9:00 - 13:00", "16:00 - 19:00"],
    "Jueves": ["9:00 - 13:00", "16:00 - 19:00"],
    "Viernes": ["9:00 - 13:00", "16:00 - 19:00"],
    "Sábado": ["10:00 - 14:00"],
    "Domingo": ["No disponible"],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false, // Quita la flecha de retroceso
        titleSpacing: 20,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Perfil de Cuidador',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textLight),
            onPressed: () {
              // Funcionalidad para editar perfil
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(),
            _buildProfileDetails(),
            _buildInterests(),
            _buildAvailability(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    final petProvider = Provider.of<PetProvider>(context);
    if (!petProvider.isLoading && petProvider.pets.isEmpty && user != null) {
      Future.microtask(() => petProvider.loadUserPets(user.id!));
    }

    return Container(
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Foto de perfil
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textLight, width: 3),
              color: Colors.white,
            ),
            child: ClipOval(
              child: user != null && user.photoUrl.isNotEmpty
                  ? Image.network(
                user.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person, size: 80, color: AppColors.primary);
                },
              )
                  : const Icon(Icons.person, size: 80, color: AppColors.primary),
            ),
          ),

          const SizedBox(height: 16),

          // Nombre del usuario
          Text(
            user != null && user.names.isNotEmpty
                ? user.names
                : "Usuario",
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          // Ubicación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: AppColors.textLight, size: 16),
              const SizedBox(width: 4),
              Text(
                location,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Calificación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRatingStars(4.8),
              const SizedBox(width: 8),
              const Text(
                "4.8 (120 reseñas)",
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }


  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _buildProfileDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sobre mí",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoCard(Icons.pets, "150+", "Paseos"),
              _buildInfoCard(Icons.history, "3+", "Años Exp."),
              _buildInfoCard(Icons.favorite, "98%", "Satisfacción"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Especialidades",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.tertiary),
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mi Disponibilidad",
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ...availability.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: entry.value.first == "No disponible"
                        ? const Text(
                      "No disponible",
                      style: TextStyle(color: Colors.grey),
                    )
                        : Wrap(
                      spacing: 8,
                      children: entry.value.map((timeSlot) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            timeSlot,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Funcionalidad para contactar al cuidador
              },
              child: const Text(
                "Contactar Cuidador",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}