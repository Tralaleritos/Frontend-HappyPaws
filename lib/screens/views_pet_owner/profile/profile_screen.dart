import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/models/nueva/user_model.dart';
import '../search/add_pet_screen.dart';
import '../search/pet_detail_screen.dart';
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  // Define the service variable here
  String service = ''; // You can set a default value or leave it empty

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      // Cargar las mascotas del usuario actual
      final authProvider = Provider.of<AuthProvider>(context);
      if (authProvider.currentUser != null) {
        final petProvider = Provider.of<PetProvider>(context, listen: false);
        petProvider.loadUserPets(authProvider.currentUser!.id!).then((_) {
          setState(() {
            _isLoading = false;
          });
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);
    final user = authProvider.currentUser;
    final pets = petProvider.pets;

    // Iniciales para el avatar (si no hay foto)
    String initials = '';
    if (user != null) {
      if (user.names.isNotEmpty) initials += user.names[0];
      if (user.lastname.isNotEmpty) initials += user.lastname[0];
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

                // Cerrar sesión
                Provider.of<AuthProvider>(context, listen: false).logout();

                // Cerrar el diálogo y navegar al login
                if (context.mounted) {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pushReplacementNamed('/login-duenio'); // Asegúrate de registrar esta ruta
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
          : user == null
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
                    // Avatar con foto o iniciales
                    user.photoUrl.isNotEmpty
                        ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(user.photoUrl),
                    )
                        : CircleAvatar(
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
                      user.fullName,
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
                          user.email,
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
                          user.phone,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => EditProfileScreen(user: user),
                          ),
                        ).then((_) {
                          // Actualizar perfil después de editar
                          setState(() {});
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
                              builder: (ctx) => AddPetsScreen(userId: user.id!, initialService: service),
                            ),
                          ).then((_) {
                            // Recargar mascotas después de añadir
                            if (user.id != null) {
                              petProvider.loadUserPets(user.id!);
                            }
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
                  if (petProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (pets.isEmpty)
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
                                  builder: (ctx) => AddPetsScreen(userId: user.id!, initialService: service),
                                ),
                              ).then((_) {
                                if (user.id != null) {
                                  petProvider.loadUserPets(user.id!);
                                }
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
                        itemCount: pets.length,
                        itemBuilder: (ctx, i) => GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => PetDetailsScreen(pet: pets[i]),
                              ),
                            ).then((_) {
                              if (user.id != null) {
                                petProvider.loadUserPets(user.id!);
                              }
                            });
                          },
                          child: _buildPetCard(
                            context,
                            pets[i].name,
                            pets[i].type,
                            pets[i].breed,
                            pets[i].photoUrls.isNotEmpty ? pets[i].photoUrls[0] : null,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
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