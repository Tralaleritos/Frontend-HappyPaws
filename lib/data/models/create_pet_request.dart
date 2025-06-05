// models/create_pet_request.dart
class CreatePetRequest {
  final String name;
  final String description;
  final String species;
  final String breed;
  final int age;
  final int ownerId;
  final String? imgUrl;

  CreatePetRequest({
    required this.name,
    required this.description,
    required this.species,
    required this.breed,
    required this.age,
    required this.ownerId,
    this.imgUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'species': species,
      'breed': breed,
      'age': age,
      'ownerId': ownerId,
      'imgUrl': imgUrl,
    };
  }
}