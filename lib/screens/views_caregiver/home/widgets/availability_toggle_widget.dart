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
  bool _isCreatingAvailability = false;
  bool _isTogglingAvailability = false;
  bool _hasInitialAvailability = false;
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

  Future<void> _checkInitialAvailabilityStatus() async {
    try {
      final hasRecord = await _getInitialAvailabilityCreated();
      setState(() {
        _hasInitialAvailability = hasRecord;
      });
    } catch (e) {
      setState(() {
        _hasInitialAvailability = false;
      });
    }
  }

  Future<void> _saveInitialAvailabilityCreated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('availability_created_${widget.caregiverId}', true);
    } catch (e) {
      print('Error guardando estado de disponibilidad: $e');
    }
  }

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
      final permission = await Permission.locationWhenInUse.request();
      if (permission.isDenied) {
        setState(() {
          _currentLocationName = 'Permisos de ubicación denegados';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

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

  Future<void> _createInitialAvailability() async {
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
      _isCreatingAvailability = true;
    });

    try {
      await _availabilityService.createCaregiverAvailability(
        caregiverId: widget.caregiverId,
        locationName: _currentLocationName,
        locationLatitude: _currentPosition!.latitude,
        locationLongitude: _currentPosition!.longitude,
      );

      await _saveInitialAvailabilityCreated();

      setState(() {
        _hasInitialAvailability = true;
        _isAvailable = true; // Se crea como disponible por defecto
      });

      _showSnackBar('¡Disponibilidad creada exitosamente!', Colors.green);
      widget.onAvailabilityChanged?.call(_isAvailable);
    } catch (e) {
      _showSnackBar('Error al crear disponibilidad: $e', Colors.red);
    } finally {
      setState(() {
        _isCreatingAvailability = false;
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
      _isTogglingAvailability = true;
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

      widget.onAvailabilityChanged?.call(_isAvailable);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() {
        _isTogglingAvailability = false;
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
            // Estado actual
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

            // Información de ubicación
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

            // Indicador de estado de disponibilidad inicial
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasInitialAvailability
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: _hasInitialAvailability
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasInitialAvailability ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16,
                    color: _hasInitialAvailability ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasInitialAvailability
                          ? 'Disponibilidad configurada'
                          : 'Disponibilidad no configurada',
                      style: TextStyle(
                        fontSize: 12,
                        color: _hasInitialAvailability ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Botón para crear disponibilidad inicial
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingAvailability ? null : _createInitialAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasInitialAvailability ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isCreatingAvailability
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  _hasInitialAvailability
                      ? 'DISPONIBILIDAD YA CREADA'
                      : 'CREAR DISPONIBILIDAD INICIAL',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Botón para cambiar disponibilidad
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTogglingAvailability ? null : _toggleAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAvailable ? Colors.red : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isTogglingAvailability
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
                      : 'PONERME DISPONIBLE',
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