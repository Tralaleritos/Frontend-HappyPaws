import 'package:flutter/material.dart';
import 'package:happyp/data/models/offers/offer.dart';
import 'package:happyp/data/service/offer_service.dart';
import 'package:provider/provider.dart';

import '../../../../data/service/auth_service.dart';
import '../../payment/payment_screen.dart';


class OfferDetailsScreen extends StatefulWidget {
  final int offerId;

  const OfferDetailsScreen({
    super.key,
    required this.offerId,
  });

  @override
  State<OfferDetailsScreen> createState() => _OfferDetailsScreenState();
}

class _OfferDetailsScreenState extends State<OfferDetailsScreen> {
  final OfferService _offerService = OfferService();
  OfferResponse? _offer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferDetails();
  }

  Future<void> _loadOfferDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final authProvider = Provider.of<AuthService>(context, listen: false);
      final token = await authProvider.getToken();
      _offerService.setAuthToken(token!);
      final offer = await _offerService.getOfferById(widget.offerId);

      if (mounted) {
        setState(() {
          _offer = offer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar los detalles: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPayment() {
    if (_offer != null) {
      final double advancePayment = _offer!.price / 2; // 50% de adelanto
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            amount: advancePayment,
            serviceName: 'Servicio de Mascotas',
            offerId: widget.offerId,
          ),
        ),
      );
    }
  }

  String _formatTime(String time) {
    // Formatear hora de HH:mm:ss a HH:mm
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      final List<String> months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];

      return '${parsedDate.day} de ${months[parsedDate.month - 1]} del ${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Oferta #${widget.offerId}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOfferDetails,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      )
          : _offer == null
          ? const Center(
        child: Text('No se encontró la oferta'),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado con precio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio del servicio',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S/. ${_offer!.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Pago 50% por adelantado',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Información de fecha y hora
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: 'Fecha y Hora',
                    children: [
                      _buildInfoRow('Fecha', _formatDate(_offer!.date)),
                      _buildInfoRow('Hora de inicio', _formatTime(_offer!.startTime)),
                      _buildInfoRow('Hora de fin', _formatTime(_offer!.endTime)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Información de ubicación
                  _buildInfoCard(
                    icon: Icons.location_on,
                    title: 'Ubicación',
                    children: [
                      _buildInfoRow('Dirección', _offer!.locationName),
                      _buildInfoRow('Coordenadas',
                          '${_offer!.locationLatitude.toStringAsFixed(4)}, ${_offer!.locationLongitude.toStringAsFixed(4)}'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  _buildInfoCard(
                    icon: Icons.description,
                    title: 'Descripción',
                    children: [
                      Text(
                        _offer!.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Mascotas
                  if (_offer!.pets.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.pets,
                      title: 'Mascotas (${_offer!.pets.length})',
                      children: [
                        ..._offer!.pets.map((pet) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Servicios
                  if (_offer!.services.isNotEmpty)
                    _buildInfoCard(
                      icon: Icons.medical_services,
                      title: 'Servicios (${_offer!.services.length})',
                      children: [
                        ..._offer!.services.map((service) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (service.description.isNotEmpty)
                                          Text(
                                            service.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _offer != null
          ? Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: _navigateToPayment,
          backgroundColor: Colors.green,
          icon: const Icon(Icons.payment, color: Colors.white),
          label: const Text(
            'Proceder al Pago',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}