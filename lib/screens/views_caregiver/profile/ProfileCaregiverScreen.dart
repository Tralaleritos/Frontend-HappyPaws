import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class ProfileCaregiverScreen extends StatelessWidget {
  const ProfileCaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Perfil de Cuidador',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('No se encontró información del cuidador'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(user),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                user.email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                user.phoneNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
