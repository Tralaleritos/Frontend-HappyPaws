import 'package:flutter/material.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/models/user/user.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:happyp/screens/views_pet_owner/add_pet/add_pet_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  bool _isLoadingPets = false;

  // Servicios
  final UserService _userService = UserService();
  final PetService _petService = PetService();

  // Estado local
  User? _currentUser;
  List<Pet> _userPets = [];

  // Define the service variable here
  String service = ''; // You can set a default value or leave it empty

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _initializeScreen();
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthService>(context, listen: false);
      final token = await authProvider.getToken();

      if (token != null) {
        // Configurar token en los servicios
        _userService.setAuthToken(token);
        _petService.setAuthToken(token);

        // Cargar datos del usuario
        await _loadUserData();

        // Cargar mascotas del usuario
        await _loadUserPets();
      }
    } catch (e) {
      print('Error inicializando ProfileScreen: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      print('Error cargando datos del usuario: $e');
    }
  }

  Future<void> _loadUserPets() async {
    setState(() {
      _isLoadingPets = true;
    });

    try {
      final pets = await _petService.getUserPets();
      setState(() {
        _userPets = pets;
      });
    } catch (e) {
      print('Error cargando mascotas: $e');
    } finally {
      setState(() {
        _isLoadingPets = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthService>(context);

    // Iniciales para el avatar (si no hay foto)
    String initials = '';
    if (_currentUser != null) {
      if (_currentUser!.username.isNotEmpty) initials += _currentUser!.username[0];
      if (_currentUser!.email.isNotEmpty) initials += _currentUser!.email[0];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
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
          : _currentUser == null
          ? const Center(child: Text('No hay usuario logueado'))
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
              child: Center(
                child: Column(
                  children: [
                    // Avatar con iniciales (ya que no tienes photoUrl en el nuevo User model)
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentUser!.username,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentUser!.email,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _currentUser!.phoneNumber,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Future.value().then((_) {
                          // Actualizar perfil después de "simular" la navegación
                          _loadUserData();
                        });
                      },
                      child: const Text('Editar Perfil'),
                    ),
                  ],
                ),
              ),
            ),
            // Sección de mascotas
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mis Mascotas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddPetScreen(ownerId: int.parse(_currentUser!.id)),
                            ),
                          ).then((_) {
                            // Recargar mascotas después de añadir
                            _loadUserPets();
                          });
                        },
                        icon: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          'Añadir',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingPets)
                    const Center(child: CircularProgressIndicator())
                  else if (_userPets.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Icon(
                            Icons.pets,
                            size: 48,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes mascotas registradas',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) => AddPetScreen(ownerId: int.parse(_currentUser!.id))
                                ),
                              ).then((_) {
                                _loadUserPets();
                              });
                            },
                            child: const Text('Añadir una mascota ahora'),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _userPets.length,
                        itemBuilder: (ctx, i) {
                          final pet = _userPets[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: pet.imgUrl.isNotEmpty
                                      ? NetworkImage(pet.imgUrl)
                                      : null,
                                  child: pet.imgUrl.isEmpty
                                      ? Icon(Icons.pets, size: 30, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pet.name,
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 5),
                  // Próximas citas (mantenemos esta sección estática como pides)
                  Text(
                    'Próximas Citas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(
                    context,
                    'Paseo con Max',
                    'María López',
                    'Mañana, 3:00 PM',
                  ),
                  const SizedBox(height: 16),
                  _buildAppointmentCard(
                    context,
                    'Veterinario para Luna',
                    'Dr. García',
                    'Viernes, 10:00 AM',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(
      BuildContext context,
      String name,
      String type,
      String breed,
      String? photoUrl,
      ) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          photoUrl != null && photoUrl.isNotEmpty
              ? CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(photoUrl),
          )
              : CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              type.toLowerCase() == 'perro'
                  ? Icons.pets
                  : type.toLowerCase() == 'gato'
                  ? Icons.face
                  : Icons.pets,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            breed,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
      BuildContext context,
      String title,
      String provider,
      String time,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    provider,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Confirmado',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}