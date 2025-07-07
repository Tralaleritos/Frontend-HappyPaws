import 'package:flutter/material.dart';
import 'package:happyp/data/models/offers/offer.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/models/user/user.dart';
import 'package:happyp/data/models/offers/accepted_offer_response.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:happyp/data/service/offer_service.dart';
import 'package:provider/provider.dart';
import 'package:happyp/screens/views_pet_owner/add_pet/add_pet_screen.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  bool _isLoadingPets = false;
  bool _isLoadingOffers = false;

  // Servicios
  final UserService _userService = UserService();
  final PetService _petService = PetService();
  final OfferService _offerService = OfferService();

  // Estado local
  User? _currentUser;
  List<Pet> _userPets = [];
  List<AcceptedOfferResponse> _acceptedOffers = [];

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
        _offerService.setAuthToken(token);

        // Cargar datos del usuario
        await _loadUserData();

        // Cargar mascotas del usuario
        await _loadUserPets();

        // Cargar ofertas aceptadas
        await _loadAcceptedOffers();
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

  Future<void> _loadAcceptedOffers() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingOffers = true;
    });

    try {
      final offers = await _offerService.getAcceptedOffers(int.parse(_currentUser!.id));
      setState(() {
        _acceptedOffers = offers;
      });
    } catch (e) {
      print('Error cargando ofertas aceptadas: $e');
    } finally {
      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      return 'Hoy, ${DateFormat('HH:mm').format(date)}';
    } else if (dateOnly == tomorrow) {
      return 'Mañana, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy, HH:mm').format(date);
    }
  }

  String _getServiceNames(List<ServiceType> services) {
    return services.map((service) => service.name).join(', ');
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

                  // Sección de Ofertas Aceptadas (reemplaza las citas estáticas)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mis Servicios Activos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_acceptedOffers.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Navegar a una pantalla con todas las ofertas
                            // Navigator.of(context).pushNamed('/accepted-offers');
                          },
                          child: const Text('Ver todo'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isLoadingOffers)
                    const Center(child: CircularProgressIndicator())
                  else if (_acceptedOffers.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Icon(
                            Icons.calendar_today,
                            size: 48,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No tienes servicios activos',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tus ofertas aceptadas aparecerán aquí',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _acceptedOffers.map((offer) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOfferCard(context, offer),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, AcceptedOfferResponse offer) {
    final isOwner = _currentUser?.id == offer.owner.id.toString();
    final otherUser = isOwner ? offer.caregiver : offer.owner;
    final userRole = isOwner ? 'Cuidador' : 'Dueño';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                        _getServiceNames(offer.services),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$userRole: ${otherUser.username}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      if (offer.pets.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Mascotas: ${offer.pets.map((pet) => pet.name).join(', ')}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(DateTime.parse(offer.range.date)),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/. ${offer.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Aceptado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (offer.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                offer.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}