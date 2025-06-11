import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _hasInitialAvailability = false; // Nuevo: controla si ya se creó el registro inicial
  final CaregiverAvailabilityService _availabilityService = CaregiverAvailabilityService();
  Position? _currentPosition;
  String _currentLocationName = 'Ubicación desconocida';

  @override
  void initState() {
    super.initState();
    _availabilityService.setAuthToken(widget.authToken);
    _getCurrentLocation();
    _checkInitialAvailabilityStatus();
  }

  // Nuevo método: verificar si ya existe un registro de disponibilidad
  Future<void> _checkInitialAvailabilityStatus() async {
    try {
      final hasRecord = await _getInitialAvailabilityCreated();
      setState(() {
        _hasInitialAvailability = hasRecord;
      });
    } catch (e) {
      // Si hay error, asumimos que no existe
      setState(() {
        _hasInitialAvailability = false;
      });
    }
  }

  // Guardar en SharedPreferences que ya se creó la disponibilidad inicial
  Future<void> _saveInitialAvailabilityCreated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('availability_created_${widget.caregiverId}', true);
    } catch (e) {
      print('Error guardando estado de disponibilidad: $e');
    }
  }

  // Obtener de SharedPreferences si ya se creó la disponibilidad inicial
  Future<bool> _getInitialAvailabilityCreated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('availability_created_${widget.caregiverId}') ?? false;
    } catch (e) {
      print('Error obteniendo estado de disponibilidad: $e');
      return false;
    }
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
        // Cambiar a NO DISPONIBLE
        await _availabilityService.setCaregiverUnavailable(
          caregiverId: widget.caregiverId,
        );
        setState(() {
          _isAvailable = false;
        });
        _showSnackBar('Ahora estás NO DISPONIBLE', Colors.red);
      } else {
        // Cambiar a DISPONIBLE
        if (!_hasInitialAvailability) {
          // Primera vez: crear el registro inicial
          await _availabilityService.createCaregiverAvailability(
            caregiverId: widget.caregiverId,
            locationName: _currentLocationName,
            locationLatitude: _currentPosition!.latitude,
            locationLongitude: _currentPosition!.longitude,
          );

          // Guardar que ya se creó la disponibilidad inicial
          await _saveInitialAvailabilityCreated();

          setState(() {
            _hasInitialAvailability = true;
            _isAvailable = true;
          });
          _showSnackBar('¡Registro creado! Ahora estás DISPONIBLE', Colors.green);
        } else {
          // Ya existe el registro: solo actualizar a disponible
          await _availabilityService.setCaregiverAvailable(
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
      }

      // Notificar el cambio
      widget.onAvailabilityChanged?.call(_isAvailable);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
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
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            // Mostrar indicador si es la primera vez
            if (!_hasInitialAvailability)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Primera vez: se creará tu perfil de disponibilidad',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
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
                  _isAvailable
                      ? 'PONERME NO DISPONIBLE'
                      : (_hasInitialAvailability
                      ? 'PONERME DISPONIBLE'
                      : 'CREAR DISPONIBILIDAD'),
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