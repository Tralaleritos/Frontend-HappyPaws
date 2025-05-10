abstract class User {
  final String email;
  final String password;
  final String name;

  User({
    required this.email,
    required this.password,
    required this.name,
  });

  String get role;

  Map<String, dynamic> toJson();

  static User fromJson(Map<String, dynamic> json) {
    switch (json['role']) {
      case 'caregiver':
        return Caregiver.fromJson(json);
      case 'pet_owner':
        return PetOwner.fromJson(json);
      default:
        throw Exception('Rol desconocido: ${json['role']}');
    }
  }
}

class Caregiver extends User {
  Caregiver({
    required String email,
    required String password,
    required String name,
  }) : super(email: email, password: password, name: name);

  @override
  String get role => 'caregiver';

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    };
  }

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    return Caregiver(
      email: json['email'],
      password: json['password'],
      name: json['name'],
    );
  }
}

class PetOwner extends User {
  PetOwner({
    required String email,
    required String password,
    required String name,
  }) : super(email: email, password: password, name: name);

  @override
  String get role => 'pet_owner';

  @override
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    };
  }

  factory PetOwner.fromJson(Map<String, dynamic> json) {
    return PetOwner(
      email: json['email'],
      password: json['password'],
      name: json['name'],
    );
  }
}