import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:happyp/data/models/user/owners_with_pets.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/service/auth_service.dart';

class SearchCaregiverScreen extends StatefulWidget {
  const SearchCaregiverScreen({super.key});

  @override
  State<SearchCaregiverScreen> createState() => _SearchCaregiverScreenState();
}

class _SearchCaregiverScreenState extends State<SearchCaregiverScreen> {
  final UserService _userService = UserService();
  List<OwnerDetailResponse>? _owners;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOwnersDetails();
  }

  Future<void> _loadOwnersDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener token del AuthService
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token != null) {
        _userService.setAuthToken(token);

        final owners = await _userService.getAllOwnersDetails();

        setState(() {
          _owners = owners;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No se encontró token de autenticación';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los dueños: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Cuidadores'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOwnersDetails,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOwnersDetails,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_owners == null || _owners!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No se encontraron dueños con mascotas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _owners!.length,
      itemBuilder: (context, index) {
        final owner = _owners![index];
        return _buildOwnerCard(owner);
      },
    );
  }

  Widget _buildOwnerCard(OwnerDetailResponse owner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del dueño
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: owner.imgUrl != null && owner.imgUrl!.isNotEmpty
                      ? NetworkImage(owner.imgUrl!)
                      : null,
                  child: owner.imgUrl == null || owner.imgUrl!.isEmpty
                      ? Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.blue[600],
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        owner.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${owner.pets.length} mascota${owner.pets.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),

            if (owner.pets.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Lista de mascotas
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mascotas:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...owner.pets.map((pet) => _buildPetItem(pet)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPetItem(PetResponse pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.orange[100],
            backgroundImage: pet.imgUrl != null && pet.imgUrl!.isNotEmpty
                ? NetworkImage(pet.imgUrl!)
                : null,
            child: pet.imgUrl == null || pet.imgUrl!.isEmpty
                ? Icon(
              Icons.pets,
              size: 20,
              color: Colors.orange[600],
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pet.species} • ${pet.breed} • ${pet.age} año${pet.age != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (pet.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    pet.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}