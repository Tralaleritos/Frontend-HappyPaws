// pet_caregiver.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PetCaregiver {
  final String id;
  final String name;
  final double rating;
  final List<String> specialties;
  final double price; // Precio por hora en soles
  final double distance; // Distancia en km
  final LatLng location;
  final String description;
  final int reviews;
  final bool isOnline;

  PetCaregiver({
    required this.id,
    required this.name,
    required this.rating,
    required this.specialties,
    required this.price,
    required this.distance,
    required this.location,
    required this.description,
    required this.reviews,
    required this.isOnline,
  });
}
