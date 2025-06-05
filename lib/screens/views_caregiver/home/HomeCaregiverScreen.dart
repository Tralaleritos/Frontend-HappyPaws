import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/nueva/pet.dart' as pet_model;
import 'package:happyp/data/service/ApiService.dart' as service;
import '../search/RecomendationPetDetail/PetDetailScreen.dart';
import '../search/SearchResultsScreen.dart';


import 'package:provider/provider.dart';

import 'package:happyp/data/models/nueva/user_model.dart';

class HomeCaregiverScreen extends StatefulWidget {
  const HomeCaregiverScreen({super.key});

  @override
  State<HomeCaregiverScreen> createState() => _HomeCaregiverScreenState();
}

class _HomeCaregiverScreenState extends State<HomeCaregiverScreen> {
  final String _currentAddress = "Av. la marina San...";
  int _currentBannerIndex = 0;
  Timer? _timer;

  final service.ApiService _apiService = service.ApiService();
  List<pet_model.Pet> _pets = [];
  bool _isLoading = true;

  final List<String> _bannerImages = [
    'assets/images/banners/banner1.jpg',
    'assets/images/banners/banner2.jpg',
    'assets/images/banners/banner3.jpg',
    'assets/images/banners/banner4.jpg',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Perros', 'icon': FontAwesomeIcons.dog, 'species': 'dog'},
    {'name': 'Gatos', 'icon': FontAwesomeIcons.cat, 'species': 'cat'},
    {'name': 'Aves', 'icon': FontAwesomeIcons.dove, 'species': 'bird'},
    {'name': 'Conejos', 'icon': FontAwesomeIcons.hippo, 'species': 'rabbit'},
    {'name': 'Reptiles', 'icon': FontAwesomeIcons.frog, 'species': 'reptile'},
    {'name': 'Peces', 'icon': FontAwesomeIcons.fish, 'species': 'fish'},
  ];

  final Set<String> _favoritePets = {};

  @override
  void initState() {
    super.initState();
    //_getCurrentLocation();
    _loadPets();
    // Timer para el carrusel de banners
    _startBannerTimer();
  }

  Future<void> _loadPets() async {
    try {
      final pets = await _apiService.getPets();
      setState(() {
        _pets = pets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _startBannerTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentBannerIndex =
              (_currentBannerIndex + 1) % _bannerImages.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildAdBanner(),
              _buildCategoriesSection(),
              _buildPopularPetsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Get the current user from the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    // Get the user's pets from the PetProvider
    final petProvider = Provider.of<PetProvider>(context);

    // If pets haven't been loaded yet, load them when the screen builds
    if (!petProvider.isLoading && petProvider.pets.isEmpty && user != null) {
      Future.microtask(() => petProvider.loadUserPets(user.id!));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saludo y ubicación
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Forma correcta de acceder al nombre del usuario
                '¡Hola, ${user != null && user.names.isNotEmpty ? user.names : "Usuario"}!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 1),
                  SizedBox(
                    width: 150,
                    child: Text(
                      _currentAddress,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Icono de configuración
          IconButton(
            onPressed: () {
              // Acción para abrir configuración
            },
            icon: const Icon(Icons.settings),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildAdBanner() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7.0),
          child: CarouselSlider.builder(
            itemCount: _bannerImages.length,
            itemBuilder: (context, index, realIndex) {
              // Determinar si este banner es el central
              bool isCentral = index == _currentBannerIndex;

              return Container(
                width: MediaQuery.of(context).size.width,
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: AssetImage(_bannerImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: isCentral
                      ? null // El banner central no tiene gradiente
                      : LinearGradient(
                    begin: index < _currentBannerIndex
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    end: index < _currentBannerIndex
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.8),
                    ],
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 120,
              viewportFraction: 0.7,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 1),
        SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _bannerImages.asMap().entries.map((entry) {
              final index = entry.key;
              final isActive = index == _currentBannerIndex;

              // Indicador circular para inactivos
              if (!isActive) {
                return Container(
                  width: 6.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                );
              }

              // Indicador tipo barra con progreso para el activo
              return Container(
                width: 20.0,
                height: 3.5,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey.withOpacity(0.3),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ProgressBarIndicator(
                      duration: const Duration(seconds: 5),
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categorías',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Explore',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () {
                    // Navegar a la categoría seleccionada
                    _searchPets(category['species']);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category['icon'],
                          color: AppColors.primary,
                          size: 27,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _searchPets(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(searchQuery: query),
      ),
    );
  }

  Widget _buildPopularPetsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'Mascotas populares',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: _pets.isEmpty ? 0 : _pets.length,
            itemBuilder: (context, index) {
              return _buildPetCard(_pets[index], index);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPetCard(pet_model.Pet pet, int index) {
    final bool isFavorite = _favoritePets.contains(pet.id);

    // Color de fondo aleatorio para la imagen
    final Color backgroundColor = AppColors.petPhotoBackgrounds[
    pet.id.hashCode % AppColors.petPhotoBackgrounds.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PetDetailScreen(pet: pet, isFavorite: isFavorite),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey,
            width: 0.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con fondo aleatorio
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: backgroundColor,
                    child: Image.network(
                      pet.photo,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),

                  // Aquí va el gradiente dentro del Stack
                  Positioned(
                    top: 90,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Botón favorito
                  Positioned(
                    top: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (_favoritePets.contains(pet.id)) {
                            _favoritePets.remove(pet.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${pet.name} eliminado de favoritos')),
                            );
                          } else {
                            _favoritePets.add(pet.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                  Text('${pet.name} añadido a favoritos')),
                            );
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : AppColors.secondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 0.8,
              color: Colors.grey[300],
            ),

            // Información de la mascota
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            pet.gender.toLowerCase() == 'hembra'
                                ? Icons.female
                                : Icons.male,
                            size: 16,
                            color: pet.gender.toLowerCase() == 'hembra'
                                ? Colors.pink
                                : Colors.blue,
                          ),
                          Text(
                            pet.gender,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.breed} • ${pet.age} años',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  // Botón de ver detalle
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetDetailScreen(
                                  pet: pet, isFavorite: isFavorite),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Ver detalles',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//animation of dots banner
class ProgressBarIndicator extends StatefulWidget {
  final Duration duration;
  final double width;
  final double height;

  const ProgressBarIndicator({
    super.key,
    required this.duration,
    required this.width,
    required this.height,
  });

  @override
  State<ProgressBarIndicator> createState() => _ProgressBarIndicatorState();
}

class _ProgressBarIndicatorState extends State<ProgressBarIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    // Inicia la animación automáticamente
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Barra de progreso de color esmeralda que avanza
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: widget.width * _controller.value,
                height: widget.height,
                decoration: BoxDecoration(
                  color: AppColors.primary, // Color esmeralda
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}