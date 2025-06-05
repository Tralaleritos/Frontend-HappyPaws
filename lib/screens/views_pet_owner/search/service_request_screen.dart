import 'package:flutter/material.dart';
import 'package:happyp/config/themes/colors/AppColors.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String serviceType;

  const ServiceRequestScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _locationName = '';
  double? _locationLatitude;
  double? _locationLongitude;

  bool _isLoading = false;

  // Simulación de mascotas disponibles
  final List<Map<String, dynamic>> _availablePets = [
    {'id': 1, 'name': 'Firulais'},
    {'id': 2, 'name': 'Canela'},
    {'id': 3, 'name': 'Rocky'},
  ];

  // Mascotas seleccionadas (ids)
  final Set<int> _selectedPets = {};

  @override
  void dispose() {
    _descriptionController.dispose();
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

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona fecha, hora de inicio y fin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_locationName.isEmpty || _locationLatitude == null || _locationLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa la ubicación completa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedPets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos una mascota'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convertir times a String HH:mm:ss
      String startTimeStr = _startTime!.format(context);
      final startParts = startTimeStr.split(RegExp(r'[: ]'));
      String startTimeFormatted =
          '${startParts[0].padLeft(2, '0')}:${startParts[1].padLeft(2, '0')}:00';

      String endTimeStr = _endTime!.format(context);
      final endParts = endTimeStr.split(RegExp(r'[: ]'));
      String endTimeFormatted =
          '${endParts[0].padLeft(2, '0')}:${endParts[1].padLeft(2, '0')}:00';

      final dataToSend = {
        "ownerId": 1, // Aquí deberías reemplazar por el usuario real si lo tienes
        "locationName": _locationName,
        "locationLatitude": _locationLatitude,
        "locationLongitude": _locationLongitude,
        "description": _descriptionController.text,
        "date": _selectedDate!.toIso8601String().split('T').first,
        "startTime": startTimeFormatted,
        "endTime": endTimeFormatted,
        "pets": _selectedPets.toList(),
      };

      print('Datos a enviar: $dataToSend');

      await Future.delayed(const Duration(seconds: 2)); // Simular llamada

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar solicitud: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPetCheckboxes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecciona tus mascotas'),
        ..._availablePets.map((pet) {
          final petId = pet['id'] as int;
          return CheckboxListTile(
            title: Text(pet['name']),
            value: _selectedPets.contains(petId),
            onChanged: (bool? selected) {
              setState(() {
                if (selected == true) {
                  _selectedPets.add(petId);
                } else {
                  _selectedPets.remove(petId);
                }
              });
            },
          );
        }).toList(),
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

              // Ubicación
              TextFormField(
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
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) =>
                      _locationLatitude = double.tryParse(val),
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
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) =>
                      _locationLongitude = double.tryParse(val),
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

              // Fecha y hora inicio / fin
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: Container(
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
                  ),
                ],
              ),
              const SizedBox(height: 16),

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

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
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
