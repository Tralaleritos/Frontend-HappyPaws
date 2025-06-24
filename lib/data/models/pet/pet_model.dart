import 'package:happyp/data/models/pet/species.dart';
import 'package:happyp/data/models/user/user.dart';

class Pet {
  final int id;
  final String name;
  final String description;
  final Species species;
  final String breed;
  final int age;
  final String imgUrl;
  final User? owner;
  final String? serviceType;
  final double? servicePrice;

  Pet({
    this.id = 0,
    required this.name,
    required this.description,
    required this.species,
    required this.breed,
    required this.age,
    this.imgUrl = '',
    this.owner,
    this.serviceType,
    this.servicePrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'species': species.value,
      'breed': breed,
      'age': age,
      'imgUrl': imgUrl,
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      species: json['species'] != null
          ? SpeciesExtension.fromString(json['species'])
          : Species.DOG,
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      imgUrl: json['imgUrl'] ?? '',
    );
  }

  Pet copyWith({
    int? id,
    String? name,
    String? description,
    Species? species,
    String? breed,
    int? age,
    String? imgUrl,
    User? owner,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      imgUrl: imgUrl ?? this.imgUrl,
      owner: owner ?? this.owner,
    );
  }

  @override
  String toString() {
    return 'Pet(id: $id, name: $name, species: $species, breed: $breed, age: $age)';
  }
}