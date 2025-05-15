import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/themes/colors/AppColors.dart';
import '../../data/models/nueva/user_model.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AddPetScreen extends StatefulWidget {
  final String initialService;
  final String userId;

  const AddPetScreen({
    Key? key,
    required this.initialService,
    required this.userId,
  }) : super(key: key);

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _typeController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  // Form values
  String _selectedService = '';
  String _selectedGender = 'Macho';
  int _age = 1;
  bool _isVaccinated = false;

  // Lista de imágenes - ahora guarda archivos File en lugar de URLs
  List<File> _petImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialService;
    _requestPermissions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    // Es mejor verificar los permisos al inicio para una mejor experiencia
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        // Use appropriate storage permissions based on Android version
        if (int.parse(Platform.operatingSystemVersion.split(' ').first) < 33)
          Permission.storage
        else
          Permission.photos,
      ].request();

      print("Permission statuses: $statuses");
    } else if (Platform.isIOS) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.photos,
      ].request();

      print("Permission statuses: $statuses");
    }
  }

  // Función para verificar y solicitar permiso de cámara
  Future<bool> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;
    print("Camera permission status: $status");

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await Permission.camera.request();
      return status.isGranted;
    }

    // Si el permiso fue denegado permanentemente, necesitamos abrir la configuración
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
          'Permiso de cámara',
          'El permiso de cámara es necesario para tomar fotos. Por favor, habilítelo en la configuración.'
      );
      return false;
    }

    return false;
  }

  // Función para verificar y solicitar permiso de galería
  Future<bool> _requestGalleryPermission() async {
    // Use the appropriate permission based on Android version
    Permission storagePermission;

    if (Platform.isAndroid) {
      // Get the Android SDK version from the build version instead of OS version string
      int? sdkInt;
      try {
        // This is safer than parsing the full OS version string
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        sdkInt = androidInfo.version.sdkInt;
        print("Android SDK version: $sdkInt");
      } catch (e) {
        print("Error getting Android SDK version: $e");
        // Default to storage permission if we can't determine the SDK version
        sdkInt = 0;
      }

      // For Android 13 and above (API level 33+), use photos permission
      if (sdkInt >= 33) {
        storagePermission = Permission.photos;
      } else {
        // For older Android versions, use storage permission
        storagePermission = Permission.storage;
      }
    } else {
      // For iOS
      storagePermission = Permission.photos;
    }

    PermissionStatus status = await storagePermission.status;
    print("Gallery permission status for $storagePermission: $status");

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await storagePermission.request();
      return status.isGranted;
    }

    // Si el permiso fue denegado permanentemente, necesitamos abrir la configuración
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
          'Permiso de galería',
          'El permiso de galería es necesario para seleccionar fotos. Por favor, habilítelo en la configuración.'
      );
      return false;
    }

    return false;
  }

  // Diálogo para mostrar cuando los permisos son denegados permanentemente
  void _showPermissionDeniedDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  // Función para tomar foto con cámara
  Future<void> _takePhoto() async {
    bool hasPermission = await _requestCameraPermission();

    if (!hasPermission) {
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Calidad de imagen reducida para optimizar almacenamiento
      );

      if (photo != null) {
        setState(() {
          _petImages.add(File(photo.path));
        });
      }
    } catch (e) {
      _showErrorDialog('Error al acceder a la cámara', e.toString());
    }
  }

  // Función para seleccionar imágenes de la galería
  Future<void> _pickImages() async {
    bool hasPermission = await _requestGalleryPermission();

    if (!hasPermission) {
      return;
    }

    try {
      final List<XFile> selectedImages = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (selectedImages.isNotEmpty) {
        setState(() {
          _petImages.addAll(selectedImages.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      _showErrorDialog('Error al acceder a la galería', e.toString());
    }
  }


  // Widget helper para las opciones de imagen
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar dialog de error
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Función para eliminar una imagen
  void _removeImage(int index) {
    setState(() {
      _petImages.removeAt(index);
    });
  }

  // Función para mostrar opciones de imagen con UI mejorada
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  'Seleccionar imagen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: const Text('Seleccionar de galería'),
                subtitle: const Text('Escoge fotos desde tu dispositivo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.photo_camera, color: Colors.white),
                ),
                title: const Text('Tomar foto'),
                subtitle: const Text('Usa la cámara para tomar una foto'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Función para validar el formulario y guardar la mascota
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Verificar que haya al menos una imagen
      if (_petImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor agregue al menos una foto de la mascota')),
        );
        return;
      }

      List<String> photoUrls = _petImages.map((file) => file.path).toList();

      // Crear objeto de mascota (modificado para manejar múltiples fotos)
      final newPet = Pet(
        name: _nameController.text,
        type: _typeController.text,
        breed: _breedController.text,
        age: _age,
        weight: double.tryParse(_weightController.text) ?? 0.0,
        gender: _selectedGender,
        vaccinated: _isVaccinated,
        photoUrls: photoUrls,
        description: _descriptionController.text,
        service: _selectedService,
        priceService: double.tryParse(_priceController.text) ?? 0.0,
        userId: widget.userId,
      );

      // Mostrar indicador de carga
      _showLoadingDialog();

      try {
        // Guardar mascota usando el provider
        final petProvider = Provider.of<PetProvider>(context, listen: false);
        bool success = await petProvider.addPet(newPet);

        // Cerrar diálogo de carga
        if (mounted) Navigator.pop(context);

        if (success) {
          // Mostrar mensaje de éxito
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mascota agregada correctamente')),
            );
            Navigator.pop(context); // Volver a la pantalla anterior
          }
        } else {
          // Mostrar mensaje de error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${petProvider.error}')),
            );
          }
        }
      } catch (e) {
        // Manejar cualquier excepción
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inesperado: $e')),
          );
        }
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text('Guardando mascota...'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Mascota - $_selectedService'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de Información Básica
                _buildSectionTitle('Información básica'),
                _buildImagePicker(),
                const SizedBox(height: 16),

                // Resto del formulario original...
                // Nombre de la mascota
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la mascota',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre de la mascota';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tipo de mascota
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de mascota (perro, gato, etc.)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el tipo de mascota';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Raza
                TextFormField(
                  controller: _breedController,
                  decoration: const InputDecoration(
                    labelText: 'Raza',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la raza de la mascota';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Edad y peso en la misma fila
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Edad (años)'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (_age > 1) {
                                    setState(() {
                                      _age--;
                                    });
                                  }
                                },
                              ),
                              Text(
                                '$_age',
                                style: const TextStyle(fontSize: 18),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    _age++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese el peso';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingrese un número válido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Género y vacunación
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Género'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Macho',
                                child: Text('Macho'),
                              ),
                              DropdownMenuItem(
                                value: 'Hembra',
                                child: Text('Hembra'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Vacunado'),
                        value: _isVaccinated,
                        onChanged: (value) {
                          setState(() {
                            _isVaccinated = value!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sección de Servicio
                _buildSectionTitle('Información del servicio'),
                const SizedBox(height: 16),

                // Servicio seleccionado
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  decoration: const InputDecoration(
                    labelText: 'Servicio',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Paseo',
                      child: Text('Paseo'),
                    ),
                    DropdownMenuItem(
                      value: 'Veterinario',
                      child: Text('Veterinario'),
                    ),
                    DropdownMenuItem(
                      value: 'Peluquería',
                      child: Text('Peluquería'),
                    ),
                    DropdownMenuItem(
                      value: 'Hospedaje',
                      child: Text('Hospedaje'),
                    ),
                    DropdownMenuItem(
                      value: 'Entrenamiento',
                      child: Text('Entrenamiento'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedService = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Precio del servicio
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio del servicio ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el precio';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción / Necesidades especiales',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón para guardar
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Guardar Mascota',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // Implementación mejorada del selector de imágenes
  Widget _buildImagePicker() {
    return Column(
      children: [
        // Mostrar carrusel de imágenes si hay alguna
        if (_petImages.isNotEmpty)
          Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: _petImages.length > 1,
                  viewportFraction: 0.8,
                  autoPlay: _petImages.length > 1,
                  autoPlayInterval: const Duration(seconds: 3),
                ),
                items: List.generate(_petImages.length, (index) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                _petImages[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Botón para eliminar imagen
                          Positioned(
                            top: 10,
                            right: 10,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              // Indicador de número de imagen actual
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, size: 18, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    '${_petImages.length} foto(s)',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),

        // Botón para agregar imágenes
        Center(
          child: InkWell(
            onTap: _showImageOptions,
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primary),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add_photo_alternate,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Agregar fotos',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}