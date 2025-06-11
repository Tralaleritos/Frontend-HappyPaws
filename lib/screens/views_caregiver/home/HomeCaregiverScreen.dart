import 'package:flutter/material.dart';
import 'package:happyp/data/service/notification_service.dart';
import 'package:happyp/screens/views_caregiver/notificactions/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:happyp/data/models/pet.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
// Importar el nuevo servicio de notificaciones

class HomeCaregiverScreen extends StatefulWidget {
  const HomeCaregiverScreen({super.key});

  @override
  State<HomeCaregiverScreen> createState() => _HomeCaregiverScreenState();
}

class _HomeCaregiverScreenState extends State<HomeCaregiverScreen> {
  List<Pet> _pets = [];
  bool _isLoading = true;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadPets();
    _initializeNotificationService();
  }

  Future<void> _loadPets() async {
    try {
      final petService = Provider.of<PetService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
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

  Future<void> _initializeNotificationService() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final user = authService.currentUser;
      final caregiverId = int.parse(authService.currentUser!.id);

      if (token != null && user != null) {
        // Inicializar el servicio de notificaciones
        _notificationService.initialize(
          authToken: token,
          userId: user.id.toString(),
          caregiverId: caregiverId, // Usar el ID del caregiver actual
          serverUrl: 'http://10.0.2.2:5000/api/v1',
        );

        // Escuchar cambios en las notificaciones
        _notificationService.addListener(_onNotificationChanged);
      }
    } catch (e) {
      print('Error al inicializar servicio de notificaciones: $e');
    }
  }

  void _onNotificationChanged() {
    // Actualizar la UI cuando lleguen nuevas notificaciones
    setState(() {});

    // Mostrar SnackBar si hay nuevas notificaciones
    if (_notificationService.unreadCount > 0) {
      final latestNotification = _notificationService.notifications.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nueva oferta: ${latestNotification.description}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Ver',
            textColor: Colors.white,
            onPressed: () {
              _navigateToNotifications();
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _navigateToNotifications() {
    // Marcar como leídas antes de navegar
    _notificationService.markAsRead();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(
          caregiverId: 2,
          serverUrl: 'http://10.0.2.2:5000/api/v1',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationChanged);
    super.dispose();
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
          // Ícono de notificaciones con indicador
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _navigateToNotifications,
                tooltip: 'Notificaciones',
              ),
              // Indicador de notificaciones no leídas
              if (_notificationService.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_notificationService.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Cambiar el IconButton simple por un PopupMenuButton igual que en ProfileScreen
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) async {
              if (value == 'logout') {
                // Mostrar un pequeño diálogo de "Cerrando sesión..."
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const AlertDialog(
                      content: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text("Cerrando sesión..."),
                        ],
                      ),
                    );
                  },
                );

                // Esperar un poco para simular una animación suave
                await Future.delayed(const Duration(seconds: 1));
                final authProvider = Provider.of<AuthService>(context, listen: false);
                // Cerrar sesión
                await authProvider.logout();

                // Cerrar el diálogo y navegar al login
                if (context.mounted) {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${user?.username ?? 'cuidador'}!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Estado de conexión de notificaciones
                Row(
                  children: [
                    Icon(
                      _notificationService.isConnected
                          ? Icons.wifi
                          : Icons.wifi_off,
                      size: 16,
                      color: _notificationService.isConnected
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _notificationService.connectionStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: _notificationService.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    if (!_notificationService.isConnected) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _notificationService.reconnect,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 28),
                        ),
                        child: const Text(
                          'Reconectar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
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