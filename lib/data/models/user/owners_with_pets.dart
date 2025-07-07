import 'dart:convert';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/user/user.dart';
import 'package:http/http.dart' as http;

// Modelo para la respuesta de detalles del dueño
class OwnerDetailResponse {
  final int id;
  final String username;
  final String? imgUrl;
  final List<PetResponse> pets;

  OwnerDetailResponse({
    required this.id,
    required this.username,
    this.imgUrl,
    required this.pets,
  });

  factory OwnerDetailResponse.fromJson(Map<String, dynamic> json) {
    return OwnerDetailResponse(
      id: json['id'],
      username: json['username'] ?? '',
      imgUrl: json['imgUrl'],
      pets: json['pets'] != null
          ? (json['pets'] as List)
          .map((petJson) => PetResponse.fromJson(petJson))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'imgUrl': imgUrl,
      'pets': pets.map((pet) => pet.toJson()).toList(),
    };
  }
}

// Modelo para la respuesta de mascota
class PetResponse {
  final int id;
  final String name;
  final String description;
  final String species; // Asumiendo que Species se serializa como String
  final String breed;
  final int age;
  final String? imgUrl;

  PetResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.species,
    required this.breed,
    required this.age,
    this.imgUrl,
  });

  factory PetResponse.fromJson(Map<String, dynamic> json) {
    return PetResponse(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      species: json['species']?.toString() ?? '',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      imgUrl: json['imgUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'species': species,
      'breed': breed,
      'age': age,
      'imgUrl': imgUrl,
    };
  }
}
