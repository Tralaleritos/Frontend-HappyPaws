import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_navigation_scaffold_alt.dart'; // Asegúrate de importar el scaffold alternativo

class HomeCaregiver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return MainNavigationScaffoldAlt(
      currentIndex: 0, // Índice correspondiente a "Inicio"
      appBar: AppBar(
        title: const Text('Cuidador - Inicio'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Bienvenido Cuidador\n${user?.username ?? ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
