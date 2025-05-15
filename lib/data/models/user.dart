class User {
  final String username;
  final String email;
  final String password;
  final String phoneNumber;
  final List<Role> roles;

  User({
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.roles,
  });

  // Getter que devuelve el rol principal como string
  String get role {
    if (roles.isEmpty) return 'OWNER'; // Valor por defecto
    return roles.first.name.toUpperCase();
  }

  // Método para verificar si el usuario tiene un rol específico
  bool hasRole(String roleName) {
    return roles.any((role) => role.name.toUpperCase() == roleName.toUpperCase());
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'roles': roles.map((role) => role.toJson()).toList(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Extraer los roles desde el JSON
    List<Role> extractedRoles = [];

    if (json['roles'] != null && json['roles'] is List) {
      extractedRoles = (json['roles'] as List)
          .where((e) => e is Map<String, dynamic>)
          .map((roleJson) => Role.fromJson(roleJson as Map<String, dynamic>))
          .toList();
    }

    return User(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      roles: extractedRoles,
    );
  }
}

// Clase que representa un rol en el sistema
class Role {
  final int id;
  final String name;

  Role({required this.id, required this.name});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() => 'Role(id: $id, name: $name)';
}