import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';
import 'package:happyp/data/models/offers/offer.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/models/pet/species.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/data/service/offer_service.dart';
import 'package:happyp/data/service/pet_service.dart';
import 'package:happyp/data/service/user_service.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';




import '../../../data/service/service_type_service.dart';
class ServiceRequestScreen extends StatefulWidget {
  final int  serviceTypeId;
  final String serviceType;

  const ServiceRequestScreen({
    super.key,
    required this.serviceTypeId,
    required this.serviceType,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  final _locationNameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();


  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _locationName = '';
  double? _locationLatitude;
  double? _locationLongitude;

  bool _isLoading = false;
  bool _loadingPets = true;
  bool _loadingServices = true;

  // Servicios
  late final OfferService _offerService;
  late final UserService _userService;
  late final PetService _petService;
  late final ServiceTypeService _serviceTypeService;

  // Mascotas del usuario obtenidas del API
  List<Pet> _availablePets = [];

  // Mascotas seleccionadas
  final Set<Pet> _selectedPets = {};

  // Servicios disponibles y seleccionados
  List<ServiceType> _availableServices = [];
  final Set<ServiceType> _selectedServices = {};

  @override
  void initState() {
    super.initState();
    _offerService = OfferService();
    _userService = UserService();
    _petService = PetService();
    _serviceTypeService = ServiceTypeService();
    _initializeServices();
    _getCurrentLocation();
  }

  Future<void> _initializeServices() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();

    if (token != null) {
      _offerService.setAuthToken(token);
      _userService.setAuthToken(token);
      _petService.setAuthToken(token);
      _serviceTypeService.setAuthToken(token);

      // Cargar datos en paralelo
      await Future.wait([
        _loadUserPets(),
        _loadAvailableServices(),
      ]);
    }
  }

  // Método para cargar las mascotas del usuario
  Future<void> _loadUserPets() async {
    try {
      setState(() {
        _loadingPets = true;
      });

      final pets = await _petService.getUserPets();

      if (mounted) {
        setState(() {
          _availablePets = pets;
          _loadingPets = false;
        });

        print('Mascotas cargadas: ${pets.length}');
        for (var pet in pets) {
          print('- ${pet.name} (ID: ${pet.id}, ${pet.breed})');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPets = false;
        });
        _showSnackBar('Error al cargar mascotas: $e', Colors.red);
        print('Error cargando mascotas: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final placemark = placemarks.first;

    setState(() {
      _locationName =
      "${placemark.street}, ${placemark.locality}, ${placemark.country}";

      _locationNameController.text = _locationName;

      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
    });
  }




  // Método para cargar servicios disponibles
  Future<void> _loadAvailableServices() async {
    try {
      setState(() {
        _loadingServices = true;
      });

      // Llamada real al API para obtener los servicios
      final services = await _serviceTypeService.getAllServiceTypes();

      if (mounted) {
        setState(() {
          _availableServices = services;
          _loadingServices = false;
        });

        print('Servicios cargados: ${services.length}');
        for (var service in services) {
          print('- ${service.name} (ID: ${service.id})');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Si falla la carga del API, usar servicios hardcodeados como fallback
          _availableServices = _getHardcodedServices();
          _loadingServices = false;
        });
        _showSnackBar('Usando servicios por defecto: $e', Colors.orange);
        print('Error cargando servicios, usando hardcoded: $e');
      }
    }
  }

  // Servicios hardcodeados (reemplaza con llamada al API)
  List<ServiceType> _getHardcodedServices() {
    return [
      ServiceType(id: 1, name: 'Paseo', description: 'Paseo diario para mascotas'),
      ServiceType(id: 2, name: 'Cuidado', description: 'Cuidado general de mascotas'),
      ServiceType(id: 3, name: 'Alimentación', description: 'Alimentación y cuidado básico'),
      ServiceType(id: 4, name: 'Veterinario', description: 'Acompañamiento veterinario'),
      ServiceType(id: 5, name: 'Guardería', description: 'Guardería temporal'),
    ];
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _locationNameController.dispose();
    _latitudeController.dispose();   // 👈 Añadir
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _startTime) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _endTime) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validaciones
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      _showSnackBar('Por favor selecciona fecha, hora de inicio y fin', Colors.red);
      return;
    }

    if (_locationName.isEmpty || _locationLatitude == null || _locationLongitude == null) {
      _showSnackBar('Por favor ingresa la ubicación completa', Colors.red);
      return;
    }

    if (_selectedPets.isEmpty) {
      _showSnackBar('Por favor selecciona al menos una mascota', Colors.red);
      return;
    }

    if (_selectedServices.isEmpty) {
      _showSnackBar('Por favor selecciona al menos un servicio', Colors.red);
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      _showSnackBar('Por favor ingresa un precio válido', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el ID del usuario actual
      String? userId = await _userService.getUserId();
      print('UserID obtenido: $userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('No se pudo obtener el ID del usuario. Por favor inicia sesión nuevamente.');
      }

      int? userIdInt = int.tryParse(userId);
      if (userIdInt == null) {
        throw Exception('ID de usuario inválido: $userId');
      }

      // Validar mascotas seleccionadas
      List<Pet> validPets = _selectedPets.where((pet) => pet.id != 0).toList();
      if (validPets.length != _selectedPets.length) {
        throw Exception('Algunas mascotas seleccionadas no tienen ID válido');
      }

      // Obtener valores actuales de los campos por si han sido editados
      _locationName = _locationNameController.text;
      _locationLatitude = double.tryParse(_latitudeController.text);
      _locationLongitude = double.tryParse(_longitudeController.text);


      // Crear la solicitud con la nueva estructura
      final request = CreateOfferRequest(
        ownerId: userIdInt,
        locationName: _locationName,
        locationLatitude: _locationLatitude!,
        locationLongitude: _locationLongitude!,
        description: _descriptionController.text,
        date: _selectedDate!.toIso8601String().split('T').first, // YYYY-MM-DD
        startTime: _formatTimeOfDay(_startTime!), // HH:mm:ss
        endTime: _formatTimeOfDay(_endTime!), // HH:mm:ss
        pets: _selectedPets.map((pet) => pet.id).toList(),
        price: price,
        services: _selectedServices.map((service) => service.id).toList(),
      );

      print('Enviando request: ${request.toString()}');

      // Enviar la solicitud al backend
      final response = await _offerService.createOffer(request);
      print('Respuesta recibida: ${response.toString()}');

      if (mounted) {
        String responseId = response.id.toString();

        _showSnackBar(
          'Solicitud enviada exitosamente. ID: $responseId',
          Colors.green,
        );
        Navigator.pop(context, response);
      }

    } catch (e) {
      print('Error completo: $e');
      if (mounted) {
        _showSnackBar('Error al enviar solicitud: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Widget _buildPetCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona tus mascotas',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),

        if (_loadingPets)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_availablePets.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.pets,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No tienes mascotas registradas',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra tus mascotas primero para poder solicitar servicios',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showSnackBar('Funcionalidad de agregar mascota pendiente', Colors.orange);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Registrar Mascota'),
                ),
              ],
            ),
          )
        else
          Column(
            children: _availablePets.map((pet) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  title: Text(
                    pet.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pet.breed} • ${pet.age} años'),
                      if (pet.description.isNotEmpty)
                        Text(
                          pet.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  secondary: CircleAvatar(
                    backgroundColor: pet.species == Species.DOG
                        ? Colors.brown[100]
                        : Colors.orange[100],
                    child: Icon(
                      pet.species == Species.DOG
                          ? Icons.pets
                          : Icons.emoji_emotions,
                      color: pet.species == Species.DOG
                          ? Colors.brown[700]
                          : Colors.orange[700],
                    ),
                  ),
                  value: _selectedPets.contains(pet),
                  onChanged: (bool? selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedPets.add(pet);
                      } else {
                        _selectedPets.remove(pet);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),

        if (!_loadingPets && _availablePets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _loadUserPets,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar mascotas'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitar ${widget.serviceType}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descripción
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe qué necesitas...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Precio
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (S/.)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el precio';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Ingresa un precio válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Ubicación
              TextFormField(
                controller: _locationNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la ubicación',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _locationName = val,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre de la ubicación';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa latitud';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Latitud inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa longitud';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Longitud inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),


              // Fecha
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate == null
                            ? 'Seleccionar fecha'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Horas
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectStartTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                            Text(
                              _startTime == null
                                  ? 'Hora inicio'
                                  : _startTime!.format(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectEndTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                            Text(
                              _endTime == null
                                  ? 'Hora fin'
                                  : _endTime!.format(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildPetCheckboxes(),

              const SizedBox(height: 16),


              const SizedBox(height: 24),

              // Botón de envío
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _loadingPets || _loadingServices ||
                      _availablePets.isEmpty)
                      ? null
                      : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Enviar Solicitud',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}