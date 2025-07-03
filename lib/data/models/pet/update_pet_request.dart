import 'package:happyp/data/models/pet/species.dart';

class UpdatePetRequest {
  final int id;
  final String name;
  final String description;
  final Species species; // Ahora usa el modelo Species
  final String breed;
  final int age;
  final String imgUrl;

  UpdatePetRequest({
    required this.id,
    required this.name,
    required this.description,
    required this.species,
    required this.breed,
    required this.age,
    required this.imgUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'species': species.value, // Convierte Species a String para JSON
      'breed': breed,
      'age': age,
      'imgUrl': imgUrl,
    };
  }
}