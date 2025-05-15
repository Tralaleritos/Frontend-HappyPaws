import 'package:flutter/material.dart';
import '../../config/themes/colors/AppColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SearchResultsScreen.dart';

class SearchRealTimeScreen extends StatefulWidget {
  const SearchRealTimeScreen({Key? key}) : super(key: key);

  @override
  State<SearchRealTimeScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchRealTimeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Sugerencias populares predefinidas
  final List<String> _popularSearches = [
    'Perro', 'Gato', 'Adopción', 'Cachorro', 'Vacunado'
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    // Configurar animación para efectos visuales
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Enfocar automáticamente el campo de búsqueda cuando se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Cargar búsquedas recientes desde SharedPreferences
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recentSearches') ?? [];
    });
  }

  // Guardar una nueva búsqueda reciente
  Future<void> _saveSearch(String query) async {
    if (query.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // Eliminar esta consulta si ya existe para evitar duplicados
    _recentSearches.remove(query);

    // Añadir la nueva consulta al principio
    _recentSearches.insert(0, query);

    // Limitar a las 5 búsquedas más recientes
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }

    // Guardar la lista actualizada
    await prefs.setStringList('recentSearches', _recentSearches);
  }

  // Generar sugerencias en tiempo real basadas en el texto de búsqueda
  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;

      // Simulación de sugerencias basadas en la entrada
      _suggestions = [
        '$query',
        '${query}s',
        '$query pequeño',
        '$query en adopción',
      ];
    });
  }

  // Realizar la búsqueda y navegar a la pantalla de resultados
  void _performSearch(String query) async {
    if (query.isEmpty) return;

    // Animación de pulsación
    _animationController.reverse().then((_) => _animationController.forward());

    // Guardar la búsqueda
    await _saveSearch(query);

    // Actualizar la UI
    setState(() {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });

    // Navegar a la pantalla de resultados con transición
    if (!mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SearchResultsScreen(searchQuery: query),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () {
            // Animación al salir
            _animationController.reverse().then((_) {
              Navigator.pop(context);
            });
          },
        ),
        titleSpacing: 0,
        title: _buildSearchField(),
      ),
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(_animation),
              child: child,
            ),
          );
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          hintText: 'Buscar mascota...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchController.text.isNotEmpty
              ? Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 12),
              constraints: const BoxConstraints(
                maxHeight: 24,
                maxWidth: 24,
              ),
              padding: EdgeInsets.zero,
              onPressed: () {
                _searchController.clear();
                _updateSuggestions('');
              },
            ),
          )
              : null,
        ),
        style: const TextStyle(fontSize: 14),
        textInputAction: TextInputAction.search,
        onChanged: _updateSuggestions,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildBody() {
    return _isSearching ? _buildSuggestions() : _buildRecentAndPopular();
  }

  Widget _buildSuggestions() {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: _suggestions.length,
        padding: const EdgeInsets.only(top: 8),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey.shade100,
          indent: 56,
        ),
        itemBuilder: (context, index) {
          return ListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            title: Text(
              _suggestions[index],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            dense: true,
            onTap: () => _performSearch(_suggestions[index]),
            trailing: Icon(
              Icons.north_west,
              size: 14,
              color: Colors.grey.shade400,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentAndPopular() {
    return Container(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de búsquedas recientes
                  if (_recentSearches.isNotEmpty) ...[
                    _buildSectionHeader('Búsquedas recientes', () {
                      setState(() {
                        _recentSearches = [];
                      });
                      SharedPreferences.getInstance().then(
                            (prefs) => prefs.remove('recentSearches'),
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildSearchChips(_recentSearches, isRecent: true),
                    const SizedBox(height: 32),
                  ],

                  // Sección de búsquedas populares
                  _buildSectionHeader('Búsquedas populares', null),
                  const SizedBox(height: 12),
                  _buildSearchChips(_popularSearches, isRecent: false),
                ],
              ),
            ),
          ),

          // Sección de tendencias (simulada)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tendencias',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTrendingSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    // Simulación de tendencias con categorías atractivas
    final List<Map<String, dynamic>> trendingItems = [
      {
        'icon': Icons.pets,
        'title': 'Adopta un amigo',
        'subtitle': 'Mascota del día',
        'color': Colors.orange,
      },
      {
        'icon': Icons.volunteer_activism,
        'title': 'Ayuda animal',
        'subtitle': 'Campañas activas',
        'color': Colors.red,
      },
      {
        'icon': Icons.local_hospital,
        'title': 'Veterinarios cercanos',
        'subtitle': 'Atención 24h',
        'color': AppColors.primary,
      },
    ];

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: trendingItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = trendingItems[index];
        return InkWell(
          onTap: () => _performSearch(item['title']),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item['color'].withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: item['color'].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item['icon'],
                    color: item['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item['subtitle'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: item['color'],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Function()? onClear) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (onClear != null)
          TextButton.icon(
            onPressed: onClear,
            icon: Icon(
              Icons.delete_outline,
              size: 16,
              color: AppColors.primary,
            ),
            label: Text(
              'Borrar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchChips(List<String> searches, {required bool isRecent}) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: searches.map((search) {
        return InkWell(
          onTap: () => _performSearch(search),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isRecent
                  ? Colors.grey.shade50
                  : AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRecent
                    ? Colors.grey.shade300
                    : AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRecent ? Icons.history_rounded : Icons.trending_up_rounded,
                  size: 14,
                  color: isRecent
                      ? Colors.grey.shade600
                      : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  search,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isRecent
                        ? Colors.grey.shade800
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}