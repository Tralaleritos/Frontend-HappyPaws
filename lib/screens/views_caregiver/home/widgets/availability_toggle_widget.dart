import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:happyp/data/service/caregiver_availability_service.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class AvailabilityToggleWidget extends StatefulWidget {
  final int caregiverId;
  final String authToken;
  final Function(bool)? onAvailabilityChanged;

  const AvailabilityToggleWidget({
    super.key,
    required this.caregiverId,
    required this.authToken,
    this.onAvailabilityChanged,
  });

  @override
  State<AvailabilityToggleWidget> createState() => _AvailabilityToggleWidgetState();
}

class _AvailabilityToggleWidgetState extends State<AvailabilityToggleWidget> {
  bool _isAvailable = false;
  bool _isLoading = false;
  final CaregiverAvailabilityService _availabilityService = CaregiverAvailabilityService();
  Position? _currentPosition;
  String _currentLocationName = 'Ubicación desconocida';

  @override
  void initState() {
    super.initState();
    _availabilityService.setAuthToken(widget.authToken);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos de ubicación
      final permission = await Permission.locationWhenInUse.request();
      if (permission.isDenied) {
        setState(() {
          _currentLocationName = 'Permisos de ubicación denegados';
        });
        return;
      }

      // Obtener posición actual
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // Obtener nombre de la ubicación
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _currentLocationName = '${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}';
        });
      }
    } catch (e) {
      setState(() {
        _currentLocationName = 'Error al obtener ubicación';
      });
    }
  }

  Future<void> _toggleAvailability() async {
    if (_currentPosition == null) {
      print(widget.authToken);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esperando ubicación...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAvailable) {
        // Poner como no disponible
        await _availabilityService.setCaregiverUnavailable(
          caregiverId: widget.caregiverId,
        );
        setState(() {
          _isAvailable = false;
        });
        _showSnackBar('Ahora estás NO DISPONIBLE', Colors.red);
      } else {
        // Poner como disponible
        await _availabilityService.createCaregiverAvailability(
          caregiverId: widget.caregiverId,
          locationName: _currentLocationName,
          locationLatitude: _currentPosition!.latitude,
          locationLongitude: _currentPosition!.longitude,
        );
        setState(() {
          _isAvailable = true;
        });
        _showSnackBar('¡Ahora estás DISPONIBLE!', Colors.green);
      }

      // Notificar el cambio
      widget.onAvailabilityChanged?.call(_isAvailable);
    } catch (e) {
      _showSnackBar('Error ayudenloooo: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(
                  _isAvailable ? Icons.check_circle : Icons.cancel,
                  color: _isAvailable ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isAvailable ? 'DISPONIBLE' : 'NO DISPONIBLE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLocationName,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_currentPosition != null)
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, '
                              'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _toggleAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAvailable ? Colors.red : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  _isAvailable ? 'PONERME NO DISPONIBLE' : 'PONERME DISPONIBLE',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}