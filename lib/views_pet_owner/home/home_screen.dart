import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../config/themes/colors/AppColors.dart';
import '../../data/models/nueva/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _PetOwnerHomeScreenState();
}

class _PetOwnerHomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  // Controlador para el mapa
  final Completer<GoogleMapController> _mapController = Completer();
  bool _isSearching = false;
  bool _showCaregiverDetails = false;
  bool _showServiceForm = false;

  //Position? _currentPosition;
  late AnimationController _searchAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  // Estado para los cuidadores visibles y favoritos
  List<PetCaregiver> _visibleCaregivers = [];
  List<PetCaregiver> _favoriteCaregivers = [];

  // Selección actual
  PetCaregiver? _selectedCaregiver;

  // Información de la mascota
  List<Pet> _userPets = [];
  Pet? _selectedPet;
  String _selectedServiceType = 'Paseo';
  DateTime _serviceDate = DateTime.now();
  TimeOfDay _serviceTime = TimeOfDay.now();
  int _serviceDuration = 60; // minutos
  double _servicePrice = 35.00;

  // Posición inicial del mapa (se actualizará con GPS)
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-12.0464, -77.0428), // Lima, Perú por defecto
    zoom: 14.0,
  );

  // Datos simulados para los cuidadores
  final List<PetCaregiver> _mockCaregivers = [
    PetCaregiver(
      id: '1',
      name: 'María López',
      rating: 4.8,
      specialties: ['Perros', 'Gatos', 'Paseos'],
      price: 35.00,
      distance: 1.2,
      location: const LatLng(-12.0864, -77.0442),
      imageUrl: 'assets/images/caregivers/caregiver1.jpg',
      description:
          'Amante de los animales con 5 años de experiencia cuidando mascotas.',
      reviews: 124,
      isOnline: true,
    ),
    PetCaregiver(
      id: '2',
      name: 'Juan Martínez',
      rating: 4.6,
      specialties: ['Perros grandes', 'Entrenamiento', 'Paseos'],
      price: 40.00,
      distance: 2.5,
      location: const LatLng(-12.0951, -77.0535),
      imageUrl: 'assets/images/caregivers/caregiver2.jpg',
      description:
          'Entrenador profesional de perros con certificación en primeros auxilios para mascotas.',
      reviews: 89,
      isOnline: true,
    ),
    PetCaregiver(
      id: '3',
      name: 'Ana García',
      rating: 4.9,
      specialties: ['Gatos', 'Medicina', 'Cuidado a domicilio'],
      price: 45.00,
      distance: 3.1,
      location: const LatLng(-12.0751, -77.0382),
      imageUrl: 'assets/images/caregivers/caregiver3.jpg',
      description:
          'Veterinaria con amplia experiencia en cuidado de mascotas a domicilio.',
      reviews: 156,
      isOnline: false,
    ),
  ];

  // Marcadores para el mapa
  final Set<Marker> _markers = {};

  final Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
          parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    _searchAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _visibleCaregivers = _mockCaregivers;

    if (_userPets.isNotEmpty) {
      _selectedPet = _userPets.first;
    }

    _requestLocationPermission();

    _addMockMarkers();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      // Mostrar mensaje de que la ubicación es necesaria
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El permiso de ubicación es necesario para encontrar cuidadores cercanos.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Just ensure permission is granted
      final status = await Permission.location.request();

      if (status.isGranted) {
        // Get the map controller
        final GoogleMapController controller = await _mapController.future;

        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(
              target: LatLng(-12.0464, -77.0428),
              // Default position until map gets user location
              zoom: 14.0,
            ),
          ),
        );

        setState(() {
          _circles.clear();
          _circles.add(
            Circle(
              circleId: const CircleId('searchArea'),
              center: const LatLng(-12.0464, -77.0428),
              // Default position
              radius: 2000,
              // 2 km radius
              fillColor: AppColors.primary.withOpacity(0.1),
              strokeColor: AppColors.primary.withOpacity(0.5),
              strokeWidth: 2,
            ),
          );
        });

        // Show user a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Centrando el mapa en tu ubicación...',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Show message that location permission is needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El permiso de ubicación es necesario para encontrar cuidadores cercanos.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _addMockMarkers() {
    // Añadir marcadores para los cuidadores simulados
    for (var caregiver in _mockCaregivers) {
      _markers.add(
        Marker(
          markerId: MarkerId(caregiver.id),
          position: caregiver.location,
          infoWindow: InfoWindow(
            title: caregiver.name,
            snippet: '${caregiver.rating} ★ - ${caregiver.distance} km',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            caregiver.isOnline
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
          onTap: () {
            _selectCaregiver(caregiver);
          },
        ),
      );
    }
  }

  void _selectCaregiver(PetCaregiver caregiver) {
    // Actualizar el estado
    setState(() {
      _selectedCaregiver = caregiver;
      _showCaregiverDetails = true;
    });

    // Centrar mapa en el cuidador seleccionado con animación
    _mapController.future.then((controller) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: caregiver.location,
            zoom: 15.0,
          ),
        ),
      );

    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      // Limpia cualquier selección previa
      _selectedCaregiver = null;
      _showCaregiverDetails = false;

      // Importante: ocultar los marcadores durante la búsqueda
      _markers.clear();
    });

    // Iniciar animación de búsqueda
    _searchAnimationController.reset();
    _searchAnimationController.forward();

    // Simular búsqueda durante 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSearching = false;

          // Mostrar los cuidadores de forma animada después de la búsqueda
          _showCaregiversAnimated();
        });
      }
    });
  }

  void _showCaregiversAnimated() {
    // Filtrar cuidadores según el tipo de servicio seleccionado (simulado)
    List<PetCaregiver> filteredCaregivers = _mockCaregivers.where((caregiver) {
      // Simular filtrado según el tipo de servicio
      if (_selectedServiceType == 'Paseo') {
        return caregiver.specialties.contains('Paseos');
      } else if (_selectedServiceType == 'Visita a domicilio') {
        return caregiver.specialties.contains('Cuidado a domicilio');
      } else if (_selectedServiceType == 'Entrenamiento') {
        return caregiver.specialties.contains('Entrenamiento');
      }
      return true; // Para otros servicios mostrar todos los cuidadores
    }).toList();

    // Actualizar la lista visible
    setState(() {
      _visibleCaregivers = filteredCaregivers;
    });

    // Mostrar cuidadores uno por uno con pequeños retrasos para crear efecto animado
    for (int i = 0; i < filteredCaregivers.length; i++) {
      Future.delayed(Duration(milliseconds: 300 * i), () {
        if (mounted) {
          setState(() {
            _addCaregiverMarker(filteredCaregivers[i]);
          });

        }
      });
    }

    // Notificar al usuario sobre los resultados
    String resultMessage = filteredCaregivers.isEmpty
        ? 'No se encontraron cuidadores disponibles para ${_selectedServiceType}'
        : 'Se encontraron ${filteredCaregivers.length} cuidadores para ${_selectedServiceType}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultMessage),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    // Centrar el mapa en el área de búsqueda
    _updateMapViewForResults(filteredCaregivers);
  }

  void _updateMapViewForResults(List<PetCaregiver> caregivers) {
    if (caregivers.isEmpty) return;

    // Obtener controlador del mapa
    _mapController.future.then((controller) {
      // Si hay un solo cuidador, centrarse en él
      if (caregivers.length == 1) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: caregivers.first.location,
              zoom: 15.0,
            ),
          ),
        );
      } else {

        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: const LatLng(-12.0464, -77.0428),
              zoom: 13.0,
            ),
          ),
        );
      }
    });
  }

  void _addCaregiverMarker(PetCaregiver caregiver) {
    // Crear un marcador con animación de pulsación
    _markers.add(
      Marker(
        markerId: MarkerId(caregiver.id),
        position: caregiver.location,
        infoWindow: InfoWindow(
          title: caregiver.name,
          snippet: '${caregiver.rating} ★ - ${caregiver.distance} km',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          caregiver.isOnline
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueOrange,
        ),
        onTap: () {
          _selectCaregiver(caregiver);
        },
      ),
    );
  }

  void _sendServiceRequest() {
    // Simular envío de solicitud
    setState(() {
      _showServiceForm = false;
    });

    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Solicitud enviada a ${_selectedCaregiver!.name}. ¡Te notificaremos cuando responda!',
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showServiceRequestForm() {
    setState(() {
      _showCaregiverDetails = false;
      _showServiceForm = true;
    });
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _searchAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Get the user's pets from the PetProvider
    final petProvider = Provider.of<PetProvider>(context);

    // If pets haven't been loaded yet, load them when the screen builds
    if (!petProvider.isLoading && petProvider.pets.isEmpty && user != null) {
      Future.microtask(() => petProvider.loadUserPets(user.id!));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Mapa como fondo
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
          ),

          // Panel superior con nombre y mascotas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre del usuario y botón de notificaciones
                  Row(
                    children: [
                      // Profile Image - Dynamic
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: user?.photoUrl.isNotEmpty == true
                            ? NetworkImage(user!.photoUrl)
                            : const AssetImage(
                            'assets/images/default_profile.png')
                        as ImageProvider,
                      ),
                      const SizedBox(width: 12),

                      // User Name and Welcome Message - Dynamic
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // Usar operador de acceso seguro con valor por defecto
                            '¡Hola, ${user?.names != null && user!.names.isNotEmpty ? user.names : "Usuario"}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            // Verificar explícitamente si el rol es exactamente 'caretaker'
                            user?.role == 'caretaker'
                                ? '¿Listo para atender mascotas hoy?'
                                : '¿Qué necesita tu mascota hoy?',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Badge(
                          label: const Text('2'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sección de mascotas - Modificada para mostrar mensaje si no hay mascotas
                  SizedBox(
                    height: 100,
                    child: petProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : petProvider.pets.isEmpty
                        ? _buildNoPetsMessage() // Nuevo widget para mostrar cuando no hay mascotas
                        : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: petProvider.pets.length + 1,
                      // +1 para el botón de agregar
                      itemBuilder: (context, index) {
                        if (index == petProvider.pets.length) {
                          // Botón para agregar nueva mascota
                          return _buildAddPetButton();
                        } else {
                          // Tarjeta de mascota existente
                          return _buildPetCard(
                              petProvider.pets[index]);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Panel de búsqueda de cuidadores
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Panel de selección de servicio
                if (!_isSearching &&
                    !_showCaregiverDetails &&
                    !_showServiceForm)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Buscar cuidador para:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Tipo de servicio
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedServiceType,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: <String>[
                                'Paseo',
                                'Visita a domicilio',
                                'Cuidado nocturno',
                                'Entrenamiento',
                                'Veterinaria'
                              ].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedServiceType = newValue!;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Botón de búsqueda
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: petProvider.pets.isEmpty
                                ? () => _showAddPetPrompt(
                                    context) // Mostrar prompt si no hay mascotas
                                : _startSearch,
                            // Iniciar búsqueda si hay mascotas
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Buscar cuidadores',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Animación de búsqueda en progreso
                if (_isSearching)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search,
                            size: 50,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Buscando cuidadores cercanos...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estamos encontrando los mejores cuidadores para $_selectedServiceType',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ],
                    ),
                  ),

                // Detalles de cuidador seleccionado
                if (_showCaregiverDetails && _selectedCaregiver != null)
                  _buildCaregiverDetailsCard(context, _selectedCaregiver!),

                // Formulario de solicitud de servicio
                if (_showServiceForm && _selectedCaregiver != null)
                  _buildServiceRequestForm(context, _selectedCaregiver!),
              ],
            ),
          ),

          // Detalles de cuidador seleccionado
          if (_showCaregiverDetails && _selectedCaregiver != null)
            _buildCaregiverDetailsCard(context, _selectedCaregiver!),

          // Formulario de solicitud de servicio
          if (_showServiceForm && _selectedCaregiver != null)
            _buildServiceRequestForm(context, _selectedCaregiver!),
        ],
      ),
      floatingActionButton: !_showCaregiverDetails && !_showServiceForm
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón para actualizar ubicación
                FloatingActionButton(
                  heroTag: 'btn1',
                  backgroundColor: Colors.white,
                  mini: true,
                  onPressed: _getCurrentLocation,
                  child:
                      const Icon(Icons.my_location, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                // Botón para ver cuidadores favoritos
                FloatingActionButton(
                  heroTag: 'btn2',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    // Implementar vista de favoritos
                  },
                  child: const Icon(Icons.favorite_border,
                      color: AppColors.secondary),
                ),
              ],
            )
          : null,
    );
  }

// Nuevo método para mostrar un mensaje cuando no hay mascotas
  Widget _buildNoPetsMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets,
                color: Colors.grey.shade600,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                '¡No tienes mascotas registradas!',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          TextButton(
            onPressed: () {
              // Navegación a la pantalla de agregar mascota
              // Navigator.push(context, MaterialPageRoute(builder: (context) => AddPetScreen()));

              // O mostrar un diálogo de registro rápido
              // _showAddPetDialog(context);
            },
            child: Text(
              'Agregar una mascota ahora',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Método para mostrar un prompt cuando el usuario intenta buscar sin mascotas
  void _showAddPetPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.pets, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Agrega una mascota primero'),
          ],
        ),
        content: const Text(
          'Para buscar cuidadores, necesitas registrar al menos una mascota en tu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Después',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navegación a la pantalla de agregar mascota
              // Navigator.push(context, MaterialPageRoute(builder: (context) => AddPetScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Agregar mascota'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPetButton() {
    return Container(
      width: 75,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.add,
              color: Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Agregar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () {
        // Implementar selección de mascota
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: pet.photoUrls.isNotEmpty
                  ? NetworkImage(pet.photoUrls.first)
                  : const AssetImage('assets/images/default_pet.png') as ImageProvider,
            ),
            const SizedBox(height: 8),
            Text(
              pet.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaregiverDetailsCard(
      BuildContext context, PetCaregiver caregiver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera con información del cuidador
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: AssetImage(caregiver.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          caregiver.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color:
                                caregiver.isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${caregiver.rating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          ' (${caregiver.reviews} reseñas)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey.shade600),
                        Text(
                          ' ${caregiver.distance} km de distancia',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Botón de favoritos
              IconButton(
                icon: const Icon(Icons.favorite_border),
                color: Colors.grey,
                onPressed: () {
                  // Añadir/quitar de favoritos
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Descripción
          Text(
            caregiver.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 12),

          // Especialidades
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: caregiver.specialties.map((specialty) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  specialty,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Precio y botón de solicitar
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Precio por hora',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '\$${caregiver.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _showServiceRequestForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Solicitar servicio'),
              ),
            ],
          ),

          // Botón para cerrar
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showCaregiverDetails = false;
                });
              },
              child: Text(
                'Volver',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRequestForm(
      BuildContext context, PetCaregiver caregiver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título y cuidador seleccionado
          Row(
            children: [
              const Text(
                'Solicitar servicio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Imagen pequeña del cuidador
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(caregiver.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                caregiver.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tipo de servicio
          const Text(
            'Tipo de servicio:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedServiceType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: <String>[
                  'Paseo',
                  'Visita a domicilio',
                  'Cuidado nocturno',
                  'Entrenamiento',
                  'Veterinaria'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedServiceType = newValue!;
                    // Actualizar precio según el servicio
                    if (newValue == 'Paseo') {
                      _servicePrice = 35.00;
                    } else if (newValue == 'Visita a domicilio') {
                      _servicePrice = 40.00;
                    } else if (newValue == 'Cuidado nocturno') {
                      _servicePrice = 50.00;
                    } else if (newValue == 'Entrenamiento') {
                      _servicePrice = 45.00;
                    } else if (newValue == 'Veterinaria') {
                      _servicePrice = 60.00;
                    }
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _serviceDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 90)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != _serviceDate) {
                          setState(() {
                            _serviceDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_serviceDate),
                              style: TextStyle(
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hora:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _serviceTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null && picked != _serviceTime) {
                          setState(() {
                            _serviceTime = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _serviceTime.format(context),
                              style: TextStyle(
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Duración del servicio
          const Text(
            'Duración (minutos):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _serviceDuration.toDouble(),
                  min: 30,
                  max: 180,
                  divisions: 5,
                  activeColor: AppColors.primary,
                  label: _serviceDuration.toString(),
                  onChanged: (double value) {
                    setState(() {
                      _serviceDuration = value.toInt();
                    });
                  },
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '$_serviceDuration',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Selección de mascota
          const Text(
            'Mascota:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _userPets.length,
              itemBuilder: (context, index) {
                final pet = _userPets[index];
                final isSelected = _selectedPet?.id == pet.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPet = pet;
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            border: isSelected
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(pet.photoUrls.first),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pet.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                                isSelected ? AppColors.primary : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          pet.breed,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Resumen de precio
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total estimado:',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${(_servicePrice * _serviceDuration / 60).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${_servicePrice.toStringAsFixed(2)}/hora',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showServiceForm = false;
                      _showCaregiverDetails = true;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _sendServiceRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Clase para modelo de cuidador de mascotas
class PetCaregiver {
  final String id;
  final String name;
  final double rating;
  final List<String> specialties;
  final double price;
  final double distance;
  final LatLng location;
  final String imageUrl;
  final String description;
  final int reviews;
  final bool isOnline;

  PetCaregiver({
    required this.id,
    required this.name,
    required this.rating,
    required this.specialties,
    required this.price,
    required this.distance,
    required this.location,
    required this.imageUrl,
    required this.description,
    required this.reviews,
    required this.isOnline,
  });
}
