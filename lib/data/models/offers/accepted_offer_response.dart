import 'package:happyp/data/models/notifications/offer_response.dart';
import 'package:happyp/data/models/offers/offer.dart';
import 'package:happyp/data/models/pet/pet_model.dart';
import 'package:happyp/data/models/user/user.dart';

class AcceptedOfferResponse {
  final int id;
  final double price;
  final String description;
  final Location location;
  final DateRange range;
  final List<Pet> pets;
  final User owner;
  final User caregiver; // Reutilizamos Owner para caregiver
  final List<ServiceType> services;

  AcceptedOfferResponse({
    required this.id,
    required this.price,
    required this.description,
    required this.location,
    required this.range,
    required this.pets,
    required this.owner,
    required this.caregiver,
    required this.services,
  });

  factory AcceptedOfferResponse.fromJson(Map<String, dynamic> json) {
    return AcceptedOfferResponse(
      id: json['id'],
      price: json['price'].toDouble(),
      description: json['description'],
      location: Location.fromJson(json['location']),
      range: DateRange.fromJson(json['range']),
      pets: (json['pets'] as List)
          .map((pet) => Pet.fromJson(pet))
          .toList(),
      owner: User.fromJson(json['owner']),
      caregiver: User.fromJson(json['caregiver']),
      services: (json['services'] as List)
          .map((service) => ServiceType.fromJson(service))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'description': description,
      'location': location,
      'range': range,
      'pets': pets.map((pet) => pet.toJson()).toList(),
      'owner': owner.toJson(),
      'caregiver': caregiver.toJson(),
      'services': services.map((service) => service.toJson()).toList(),
    };
  }
}