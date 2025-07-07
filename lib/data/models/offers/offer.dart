import 'package:happyp/data/models/pet/pet_model.dart';

class CreateOfferRequest {
  final int ownerId;
  final String locationName;
  final double locationLatitude;
  final double locationLongitude;
  final String description;
  final String date; // LocalDate como String en formato YYYY-MM-DD
  final String startTime; // LocalTime como String en formato HH:mm:ss
  final String endTime; // LocalTime como String en formato HH:mm:ss
  final List<int> pets; // Solo IDs de las mascotas
  final double price;
  final List<int> services; // Lista de IDs de servicios

  CreateOfferRequest({
    required this.ownerId,
    required this.locationName,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.pets,
    required this.price,
    required this.services,
  });

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'locationName': locationName,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'description': description,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'pets': pets,
      'price': price,
      'services': services,
    };
  }

  @override
  String toString() {
    return 'CreateOfferRequest{'
        'ownerId: $ownerId, '
        'locationName: $locationName, '
        'locationLatitude: $locationLatitude, '
        'locationLongitude: $locationLongitude, '
        'description: $description, '
        'date: $date, '
        'startTime: $startTime, '
        'endTime: $endTime, '
        'pets: $pets, '
        'price: $price, '
        'services: $services'
        '}';
  }
}

// Response de oferta (puedes mantener la estructura existente o simplificarla)
class OfferResponse {
  final int id;
  final int ownerId;
  final String locationName;
  final double locationLatitude;
  final double locationLongitude;
  final String description;
  final String date;
  final String startTime;
  final String endTime;
  final List<Pet> pets;
  final double price;
  final List<ServiceType> services;
  final DateTime createdAt;
  final DateTime updatedAt;

  OfferResponse({
    required this.id,
    required this.ownerId,
    required this.locationName,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.pets,
    required this.price,
    required this.services,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfferResponse.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final range = json['range'] as Map<String, dynamic>? ?? {};

    return OfferResponse(
      id: json['id'] ?? 0,
      ownerId: json['owner']['id'] ?? 0,
      locationName: loc['name'] ?? '',
      locationLatitude: (loc['latitude'] ?? 0.0).toDouble(),
      locationLongitude: (loc['longitude'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      date: range['date'] ?? '',
      startTime: range['startTime'] ?? '',
      endTime: range['endTime'] ?? '',
      pets: (json['pets'] as List<dynamic>? ?? [])
          .map((p) => Pet.fromJson(p as Map<String, dynamic>))
          .toList(),
      price: (json['price'] ?? 0.0).toDouble(),
      services: (json['services'] as List<dynamic>? ?? [])
          .map((s) => ServiceType.fromJson(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'OfferResponse{'
        'id: $id, '
        'ownerId: $ownerId, '
        'locationName: $locationName, '
        'description: $description, '
        'date: $date, '
        'startTime: $startTime, '
        'endTime: $endTime, '
        'pets: ${pets.map((p) => p.name).join(", ")}, '
        'price: $price, '
        'services: ${services.map((s) => s.name).join(", ")}'
        '}';
  }
}

// Modelo para tipos de servicio
class ServiceType {
  final int id;
  final String name;
  final String description;

  ServiceType({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceType{id: $id, name: $name}';
}