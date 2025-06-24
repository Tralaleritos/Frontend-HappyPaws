import 'package:flutter/material.dart';
import 'package:happyp/data/service/notification_service.dart';
import 'package:happyp/screens/views_caregiver/home/widgets/availability_toggle_widget.dart';
import 'package:happyp/screens/views_caregiver/notificactions/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class HomeCaregiverScreen extends StatefulWidget {
  const HomeCaregiverScreen({super.key});

  @override
  State<HomeCaregiverScreen> createState() => _HomeCaregiverScreenState();
}

class _HomeCaregiverScreenState extends State<HomeCaregiverScreen> {
  // Variables de estado
  bool _isLoading = true; // Cambiar de 'final' a 'bool' para poder modificarla
  final NotificationService _notificationService = NotificationService();

  // Variables para el caregiver actual
  int? _currentCaregiverId;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationChanged);
    super.dispose();
  }

  // ===================== MÉTODOS DE INICIALIZACIÓN =====================

  Future<void> _initializeScreen() async {
    try {
      await _loadUserData();
      await _initializeNotificationService();
    } catch (e) {
      print('Error en inicialización: $e');
      _showErrorSnackBar('Error al inicializar la aplicación: $e');
    } finally {
      // Importante: actualizar el estado cuando termine la carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userService = UserService();

      await authService.fetchAndSetUserId(userService);

      _authToken = await authService.getToken();
      final user = authService.currentUser;

      if (user != null) {
        _currentCaregiverId = int.tryParse(user.id);
        if (_currentCaregiverId == null) {
          throw Exception('ID de cuidador inválido');
        }
      } else {
        throw Exception('Usuario no encontrado');
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos del usuario: $e');
      throw e; // Re-lanzar la excepción para que sea manejada en _initializeScreen
    }
  }


  Future<void> _initializeNotificationService() async {
    if (_authToken == null || _currentCaregiverId == null) {
      print('No se puede inicializar el servicio de notificaciones: datos faltantes');
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        _notificationService.initialize(
          authToken: _authToken!,
          userId: user.id.toString(),
          caregiverId: _currentCaregiverId!,
          serverUrl: 'http://10.0.2.2:5000/api/v1',
        );

        _notificationService.addListener(_onNotificationChanged);
      }
    } catch (e) {
      print('Error al inicializar servicio de notificaciones: $e');
      // No re-lanzar aquí ya que las notificaciones no son críticas para la carga inicial
    }
  }

  // ===================== MANEJO DE NOTIFICACIONES =====================

  void _onNotificationChanged() {
    if (!mounted) return;

    setState(() {});

    if (_notificationService.unreadCount > 0) {
      final latestNotification = _notificationService.notifications.first;
      _showNotificationSnackBar(latestNotification.description);
    }
  }

  void _showNotificationSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nueva oferta: $message'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Ver',
          textColor: Colors.white,
          onPressed: _navigateToNotifications,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateToNotifications() {
    if (_currentCaregiverId == null) {
      _showErrorSnackBar('Error: ID de cuidador no disponible');
      return;
    }

    _notificationService.markAsRead();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          caregiverId: _currentCaregiverId!, // Usar el ID real del cuidador
          serverUrl: 'http://10.0.2.2:5000/api/v1',
        ),
      ),
    );
  }

  // ===================== OTROS MÉTODOS =====================

  void _onAvailabilityChanged(bool isAvailable) {
    print('Disponibilidad cambiada: $isAvailable');
    // Aquí puedes agregar lógica adicional cuando cambie la disponibilidad
  }

  Future<void> _handleLogout() async {
    _showLoadingDialog('Cerrando sesión...');

    try {
      await Future.delayed(const Duration(seconds: 1));
      final authProvider = Provider.of<AuthService>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.of(context).pop(); // Cierra el diálogo
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Cierra el diálogo
        _showErrorSnackBar('Error al cerrar sesión: $e');
      }
    }
  }

  // ===================== MÉTODOS DE UI HELPER =====================

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  // ===================== WIDGETS DE UI =====================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Bienvenido Cuidador'),
      backgroundColor: AppColors.primary,
      actions: [
        _buildNotificationIcon(),
        _buildSettingsMenu(),
      ],
    );
  }


  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _navigateToNotifications,
          tooltip: 'Notificaciones',
        ),
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
    );
  }

  Widget _buildSettingsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings),
      onSelected: (value) async {
        if (value == 'logout') {
          await _handleLogout();
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
    );
  }

  Widget _buildWelcomeHeader() {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Padding(
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
          _buildConnectionStatus(),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Row(
      children: [
        Icon(
          _notificationService.isConnected ? Icons.wifi : Icons.wifi_off,
          size: 16,
          color: _notificationService.isConnected ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          _notificationService.connectionStatus,
          style: TextStyle(
            fontSize: 12,
            color: _notificationService.isConnected ? Colors.green : Colors.red,
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
    );
  }

  Widget _buildAvailabilityToggle() {
    if (_currentCaregiverId == null || _authToken == null) {
      return const Center(
        child: Text('Error al cargar datos del cuidador'),
      );
    }

    return AvailabilityToggleWidget(
      caregiverId: _currentCaregiverId!,
      authToken: _authToken!,
      onAvailabilityChanged: _onAvailabilityChanged,
    );
  }

  // ===================== BUILD PRINCIPAL =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando...'),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          _buildAvailabilityToggle(),
        ],
      ),
    );
  }
}