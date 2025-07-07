import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/offer_service.dart';
import 'package:happyp/data/models/offers/accepted_offer_response.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class ProfileCaregiverScreen extends StatefulWidget {
  const ProfileCaregiverScreen({super.key});

  @override
  State<ProfileCaregiverScreen> createState() => _ProfileCaregiverScreenState();
}

class _ProfileCaregiverScreenState extends State<ProfileCaregiverScreen> {
  final OfferService _offerService = OfferService();
  List<AcceptedOfferResponse> _acceptedOffers = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAcceptedOffers();
    });
  }

  Future<void> _loadAcceptedOffers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthService>(context, listen: false);
      final token = await authProvider.getToken();
      if (token != null) {
        _offerService.setAuthToken(token);
      }

      final offers = await _offerService.getAcceptedOffers(int.parse(user.id));
      setState(() {
        _acceptedOffers = offers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar ofertas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Perfil de Cuidador',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('No se encontró información del cuidador'))
          : RefreshIndicator(
        onRefresh: _loadAcceptedOffers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 20),
              _buildAcceptedOffersSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                user.email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                user.phoneNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedOffersSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ofertas Aceptadas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildAcceptedOffersList(),
        ],
      ),
    );
  }

  Widget _buildAcceptedOffersList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAcceptedOffers,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_acceptedOffers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No tienes ofertas aceptadas aún',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _acceptedOffers.length,
      itemBuilder: (context, index) {
        final offer = _acceptedOffers[index];
        return _buildOfferCard(offer);
      },
    );
  }

  Widget _buildOfferCard(AcceptedOfferResponse offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con precio y dueño
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Oferta de ${offer.owner.username}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'S/. ${offer.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Descripción
            Text(
              offer.description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            // Fechas
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),

                Text(
                  _formatDate(DateTime.parse(offer.range.date)),
                  style: const TextStyle(fontSize: 14),
                ),

              ],
            ),
            const SizedBox(height: 8),

            // Mascotas
            Row(
              children: [
                const Icon(Icons.pets, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${offer.pets.length} mascota${offer.pets.length != 1 ? 's' : ''}: ${offer.pets.map((pet) => pet.name).join(', ')}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Servicios
            if (offer.services.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.medical_services, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Servicios: ${offer.services.map((service) => service.name).join(', ')}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

}