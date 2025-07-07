import '../pet/pet_model.dart';
import '../user/user.dart';

class OwnerWithPets {
  final int id;
  final String username;
  final String? imgUrl;
  final List<Pet> pets;

  OwnerWithPets({
    required this.id,
    required this.username,
    this.imgUrl,
    required this.pets,
  });

  factory OwnerWithPets.fromJson(Map<String, dynamic> json) {
    return OwnerWithPets(
      id: json['id'],
      username: json['username'],
      imgUrl: json['imgUrl'],
      pets: (json['pets'] as List<dynamic>)
          .map((petJson) => Pet.fromJson(petJson))
          .toList(),
    );
  }

  User toUser() {
    return User(
      id: id.toString(),
      username: username,
      email: '', // valor dummy o por defecto
      password: '',
      phoneNumber: '',
      roles: [], // o [Role.USER] si tienes un valor por defecto
    );
  }

}
