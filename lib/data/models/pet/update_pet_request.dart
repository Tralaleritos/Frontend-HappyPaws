class UpdatePetRequest {
  final int id;
  final String name;
  final String description;
  final String species; // Species se tratará como String en JSON
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
      'species': species,
      'breed': breed,
      'age': age,
      'imgUrl': imgUrl,
    };
  }
}