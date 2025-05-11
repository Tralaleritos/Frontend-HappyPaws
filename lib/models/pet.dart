// lib/models/pet.dart
class Pet {
  final String name;
  final String specie;
  final String breed;
  final int age;
  final String description;

  Pet({
    required this.name,
    required this.specie,
    required this.breed,
    required this.age,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'specie': specie,
    'breed': breed,
    'age': age,
    'description': description,
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    name: json['name'],
    specie: json['specie'],
    breed: json['breed'],
    age: json['age'],
    description: json['description'],
  );
}