class Vet {
  final String id;
  final String name;
  final String specialty;
  final String photo;
  final String address;
  final String phone;
  final String rating;

  Vet({
    required this.id,
    required this.name,
    required this.specialty,
    required this.photo,
    required this.address,
    required this.phone,
    required this.rating,
  });

  factory Vet.fromJson(Map<String, dynamic> json) {
    return Vet(
      id: json['id'].toString(),
      name: json['name'].toString(),
      specialty: json['specialty'].toString(),
      photo: json['photo_url'].toString(),
      address: json['address'].toString(),
      phone: json['phone'].toString(),
      rating: json['rating'].toString(),
    );
  }
}