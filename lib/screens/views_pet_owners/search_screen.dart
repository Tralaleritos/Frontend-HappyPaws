import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/caregiver_profile.dart';
import '../../services/data_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/main_navigation_scaffold.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CaregiverProfile> _caregivers = [];
  List<CaregiverProfile> _filteredCaregivers = [];
  final _dataService = DataService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final caregivers = await _dataService.getCaregiverProfiles();
      setState(() {
        _caregivers = caregivers;
        _filteredCaregivers = caregivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfiles: $e')),
        );
      }
    }
  }

  void _filterCaregivers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCaregivers = _caregivers;
      } else {
        _filteredCaregivers = _caregivers.where((caregiver) {
          return caregiver.name.toLowerCase().contains(query.toLowerCase()) ||
              caregiver.specialty.toLowerCase().contains(query.toLowerCase()) ||
              caregiver.description.toLowerCase().contains(query.toLowerCase()) ||
              caregiver.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        }).toList();
      }
    });
  }

  void _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todos los perfiles?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.clearAllProfiles();
      await _loadCaregivers();
    }
  }

  Future<void> _logout() async {
    // Mostrar diálogo de confirmación
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cerrar sesión'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmLogout) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/inicio', (_) => false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Impedir el comportamiento normal de retroceso
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _logout();
      },
      child: MainNavigationScaffold(
        currentIndex: 1,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Eliminar el botón back por defecto
          title: const Text('Happy Paws'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: _logout,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar servicios o cuidadores',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                onChanged: _filterCaregivers,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resultados (${_filteredCaregivers.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_caregivers.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar todo'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCaregivers.isEmpty
                    ? Center(
                  child: Text(
                    _caregivers.isEmpty
                        ? 'No hay cuidadores disponibles'
                        : 'No se encontraron resultados para "${_searchController.text}"',
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: _loadCaregivers,
                  child: ListView.builder(
                    itemCount: _filteredCaregivers.length,
                    itemBuilder: (context, index) {
                      final caregiver = _filteredCaregivers[index];
                      return _buildSearchResultCard(caregiver);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(CaregiverProfile caregiver) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Text(
                    caregiver.name.isNotEmpty ? caregiver.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caregiver.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                      Text(caregiver.specialty, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(caregiver.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(caregiver.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            if (caregiver.tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: caregiver.tags
                    .map(
                      (tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                )
                    .toList(),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Desde \$${caregiver.price.toStringAsFixed(2)}/hora',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vista de detalle en desarrollo')),
                    );
                  },
                  child: const Text('Ver perfil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}