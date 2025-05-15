import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/themes/colors/AppColors.dart';
import '../../../data/models/vet.dart';
import '../../../data/models/pet.dart';
import '../../../data/service/ApiService.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;
  final bool isFavorite;

  const PetDetailScreen({
    Key? key,
    required this.pet,
    required this.isFavorite,
  }) : super(key: key);

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  late bool _isFavorite;
  final ApiService _apiService = ApiService();
  List<Vet> _vets = [];
  bool _isLoading = true;

  final List<PetService> _services = [
    PetService(
      name: 'Paseo',
      icon: Icons.directions_walk,
      price: '15',
      description: 'Paseo de 30 minutos',
      color: Colors.blue,
    ),
    PetService(
      name: 'Baño',
      icon: Icons.bathtub,
      price: '25',
      description: 'Baño completo y secado',
      color: Colors.purple,
    ),
    PetService(
      name: 'Veterinario',
      icon: Icons.healing,
      price: '35',
      description: 'Consulta general',
      color: Colors.red,
    ),
    PetService(
      name: 'Corte',
      icon: Icons.content_cut,
      price: '20',
      description: 'Corte de pelo',
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _loadVets();
  }

  Future<void> _loadVets() async {
    try {
      final vets = await _apiService.getVets();
      setState(() {
        _vets = vets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar veterinarios: $e')),
        );
      }
    }
  }

  // Diálogo para negociar precio
  void _showNegotiateDialog() {
    double offeredPrice = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Negociar precio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Haz una oferta para los servicios de ${widget.pet.name}'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  labelText: 'Tu oferta',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    offeredPrice = double.tryParse(value) ?? 0;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (offeredPrice > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Oferta de \${offeredPrice.toStringAsFixed(2)} enviada al dueño'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa una oferta válida'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Enviar oferta'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SafeArea(

              child: Stack(
                children: [

                  Container(
                    height: 300,
                    width: double.infinity,
                    color: AppColors.petPhotoBackgrounds[
                    widget.pet.id.hashCode % AppColors.petPhotoBackgrounds.length
                    ],
                    child: Hero(
                      tag: 'pet-${widget.pet.id}',
                      child: Center( // <- Asegura que esté centrada
                        child: Image.network(
                          widget.pet.photo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.error, color: Colors.grey[400], size: 60);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Botón de regresar
                  Positioned(
                    top: 20,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  // Botón de favorito
                  Positioned(
                    top: 20,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFavorite = !_isFavorite;
                          final String message = _isFavorite
                              ? '${widget.pet.name} añadido a favoritos'
                              : '${widget.pet.name} eliminado de favoritos';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : AppColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Información de la mascota
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la mascota
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.pet.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.pet.gender.toLowerCase() == 'hembra' ? Icons.female : Icons.male,
                              size: 18,
                              color: widget.pet.gender.toLowerCase() == 'hembra' ? Colors.pink : Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.pet.gender,
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.pet.gender.toLowerCase() == 'hembra' ? Colors.pink : Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Detalles de la mascota
                  Text(
                    '${widget.pet.species} • ${widget.pet.breed} • ${widget.pet.age} años',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),

                  // Descripción de la mascota
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.notes,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),

                  const SizedBox(height: 6),

                  // Información del dueño
                  Row(
                    children: [
                      // Info del dueño
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dueño',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    widget.pet.owner,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botón circular de chat
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(FontAwesomeIcons.solidCommentDots),
                          iconSize: 28,
                          color: Colors.white,
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Abriendo chat con el dueño')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            // Carrusel de servicios
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                'Servicios disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            CarouselSlider(
              options: CarouselOptions(
                height: 120,
                enableInfiniteScroll: false,
                viewportFraction: 0.3,
                enlargeCenterPage: false,
                padEnds: false,
              ),
              items: _services.map((service) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: service.color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              service.icon,
                              color: service.color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            widget.pet.priceService,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            // Veterinarios disponibles
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
              child: Text(
                'Veterinarios disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vets.isEmpty
                ? Center(
              child: Text(
                'No hay veterinarios disponibles',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
                : SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _vets.length,
                itemBuilder: (context, index) {
                  final vet = _vets[index];
                  return Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: vet.photo != null && vet.photo!.isNotEmpty
                              ? Image.network(
                            vet.photo!,
                            width: 70,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  width: 70,
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                ),
                          )
                              : Container(
                            width: 70,
                            height: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  vet.name ?? 'Veterinario',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  vet.specialty ?? 'Especialidad',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.star, size: 14, color: Colors.amber[700]),
                                    const SizedBox(width: 2),
                                    Text(
                                      //vet.rating?.toString() ?? '5.0',
                                       '5.0',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Botones finales
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Botón de Negociar precio
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Lógica para negociar precio
                        _showNegotiateDialog();
                      },
                      icon: const Icon(Icons.handshake),
                      label: const Text('Negociar precio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase auxiliar para los servicios
class PetService {
  final String name;
  final IconData icon;
  final String price;
  final String description;
  final Color color;

  PetService({
    required this.name,
    required this.icon,
    required this.price,
    required this.description,
    required this.color,
  });
}