import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes/colors/AppColors.dart';
import '../../data/models/nueva/user_model.dart';
import 'add_pet_screen.dart';
import 'pet_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? userId;

  const SearchScreen({super.key, this.userId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  int _currentBannerIndex = 0;
  final List<String> _bannerImages = [
    'assets/images/banners/cuid1.jpg',
    'assets/images/banners/cuid2.jpg',
    'assets/images/banners/cuid3.jpg',
    'assets/images/banners/cuid4.jpg',
    'assets/images/banners/cuid5.jpg',
    'assets/images/banners/cuid6.jpg',
    'assets/images/banners/cuid7.jpg',
    'assets/images/banners/cuid8.jpg',
    'assets/images/banners/cuid9.jpg',
  ];

  // Filtros de búsqueda
  String _searchQuery = '';
  String _selectedService = '';
  List<Pet> _filteredPets = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Cargar todas las mascotas al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllPets();
    });
  }

  Future<void> _loadAllPets() async {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    // Obtener todas las mascotas
    await petProvider.loadUserPets(widget.userId!);
    setState(() {
      _filteredPets = petProvider.pets;
    });
  }

  void _filterPets() {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    setState(() {
      // Filtrar por nombre de mascota o nombre de dueño
      _filteredPets = petProvider.pets.where((pet) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesQuery = pet.name.toLowerCase().contains(searchLower) ||
            (pet.userId?.toLowerCase().contains(searchLower) ?? false);

        // Si hay un servicio seleccionado, filtrar también por servicio
        final matchesService =
            _selectedService.isEmpty || pet.service == _selectedService;

        return matchesQuery && matchesService;
      }).toList();
    });
  }

  // Método para agregar una nueva mascota según el servicio seleccionado
  void _navigateToAddPet(String service) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPetScreen(
            initialService: service,
            userId: authProvider.currentUser!.id!,
          ),
        ),
      ).then((_) => _loadAllPets()); // Recargar las mascotas al volver
    } else {
      _showLoginDialog();
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar sesión requerido'),
        content: const Text('Debes iniciar sesión para realizar esta acción.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí puedes navegar a la pantalla de inicio de sesión
              // Navigator.pushNamed(context, '/login');
            },
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  void _navigateToPetDetail(Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailsScreen(pet: pet),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey, width: 0.3),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _isSearching = value.isNotEmpty;
                  });
                  _filterPets();
                },
                decoration: InputDecoration(
                  hintText: 'Buscar mascota o dueño...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_isSearching)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _isSearching = false;
                  });
                  _filterPets();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Servicios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_selectedService.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedService = '';
                    });
                    _filterPets();
                  },
                  child: const Text('Ver todos'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _buildServiceCard(context, 'Paseo', Icons.directions_walk),
              _buildServiceCard(context, 'Veterinario', Icons.local_hospital),
              _buildServiceCard(context, 'Peluquería', Icons.content_cut),
              _buildServiceCard(context, 'Hospedaje', Icons.hotel),
              _buildServiceCard(context, 'Entrenamiento', Icons.sports),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, IconData icon) {
    final bool isSelected = _selectedService == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedService = isSelected ? '' : title;
        });
        _filterPets();
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
              : Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 40,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null,
                      ),
                ),
              ],
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: Icon(
                  Icons.add_circle,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 28,
                ),
                onPressed: () => _navigateToAddPet(title),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetList() {
    final petProvider = Provider.of<PetProvider>(context);

    if (petProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredPets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron mascotas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty || _selectedService.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _selectedService = '';
                    _isSearching = false;
                  });
                  _filterPets();
                },
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filteredPets.length,
        itemBuilder: (context, index) {
          final pet = _filteredPets[index];
          return _buildPetCard(pet);
        },
      ),
    );
  }

  ImageProvider getImageProvider(String path) {
    if (path.startsWith('http') || path.startsWith('https')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  Widget _buildPetCard(Pet pet) {
    return GestureDetector(
      onTap: () => _navigateToPetDetail(pet),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey, width: 0.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la mascota
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    pet.photoUrls.isNotEmpty
                        ? PageView.builder(
                            itemCount: pet.photoUrls.length,
                            itemBuilder: (context, index) {
                              return Image(
                                image: getImageProvider(pet.photoUrls[index]),
                                fit: BoxFit.contain,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/default_pet.jpg',
                            fit: BoxFit.cover,
                          ),
                    // Banner del servicio
                    Positioned(
                      top: 12,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(20)),
                        ),
                        child: Text(
                          pet.service,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Precio del servicio
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '\$${pet.priceService.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Detalles de la mascota
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            pet.gender == 'Macho' ? Icons.male : Icons.female,
                            color: pet.gender == 'Macho'
                                ? Colors.blue
                                : Colors.pink,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pet.age} años',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pet.type} - ${pet.breed}',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pet.userId ?? 'Dueño desconocido',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Botón para ver detalle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => _navigateToPetDetail(pet),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Ver detalle'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 7),
            _buildAdBanner(),
            const SizedBox(height: 15),
            _buildServiceCategories(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _selectedService.isEmpty
                    ? 'Todas las Mascotas'
                    : 'Mascotas - $_selectedService',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildPetList(),
          ],
        ),
      ),
    );
  }
}

// Widget para la barra de progreso del carousel
class ProgressBarIndicator extends StatefulWidget {
  final Duration duration;
  final double width;
  final double height;

  const ProgressBarIndicator({
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
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: 0, end: widget.width).animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Stack(
        children: [
          Container(
            width: _animation.value,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.0),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
