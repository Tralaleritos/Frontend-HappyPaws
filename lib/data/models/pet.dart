class Pet {
  final String id;
  final String name;
  final String species;
  final String breed;
  final String age;
  final String gender;
  final String photo;
  final String owner;
  final String notes;
  final String priceService;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    required this.gender,
    required this.photo,
    required this.owner,
    required this.notes,
    required this.priceService,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'].toString(),
      name: json['name'].toString(),
      species: json['species'].toString(),
      breed: json['breed'].toString(),
      age: json['age'].toString(),
      gender: json['gender'].toString(),
      photo: json['photo'].toString(),
      owner: json['owner'].toString(),
      notes: json['notes'].toString(),
      priceService: json['priceService'].toString(),
    );
  }
}