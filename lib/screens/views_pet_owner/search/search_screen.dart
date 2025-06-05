import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/screens/views_pet_owner/search/widgets/carousel_ads.dart';
import 'package:happyp/screens/views_pet_owner/search/widgets/pet_cards_grid.dart';
import 'package:happyp/screens/views_pet_owner/search/widgets/service_cards_row.dart';
import 'controllers/pet_search_controller.dart';

class SearchScreen extends StatefulWidget {
  final String? userId;

  const SearchScreen({super.key, this.userId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late PetSearchController _controller;

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

  @override
  void initState() {
    super.initState();
    _controller = PetSearchController(context);

    // Inicializar y cargar mascotas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initializeService();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                onChanged: (value) => _controller.updateSearchQuery(value),
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
            if (_controller.isSearching)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                onPressed: () => _controller.updateSearchQuery(''),
              ),
          ],
        ),
      ),
    );
  }

  void _handleError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 7),
                CarouselAds(bannerImages: _bannerImages),
                const SizedBox(height: 15),
                ServiceCardsRow(
                  selectedService: _controller.selectedService,
                  onServiceSelected: _controller.updateSelectedService,
                  onAddPetPressed: (service) =>
                      _controller.navigateToAddService(context, service),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _controller.selectedService.isEmpty
                        ? 'Todas las Mascotas'
                        : 'Mascotas - ${_controller.selectedService}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PetCardsGrid(
                  pets: _controller.filteredPets,
                  isLoading: _controller.isLoading,
                  searchQuery: _controller.searchQuery,
                  selectedService: _controller.selectedService,
                  onRefresh: () async {
                    try {
                      await _controller.loadAllPets();
                    } catch (e) {
                      _handleError(e);
                    }
                  },
                  onClearFilters: _controller.clearFilters,
                  onPetTap: (pet) => _controller.navigateToPetDetail(context, pet),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}