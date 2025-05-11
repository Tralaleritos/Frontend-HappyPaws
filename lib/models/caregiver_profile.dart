class CaregiverProfile {
  final String name;
  final String specialty;
  final String description;
  final List<String> tags;
  final double price;
  final double rating;

  CaregiverProfile({
    required this.name,
    required this.specialty,
    required this.description,
    required this.tags,
    required this.price,
    this.rating = 4.8,
  });

  // Método para crear una copia del objeto con algunos campos modificados
  CaregiverProfile copyWith({
    String? name,
    String? specialty,
    String? description,
    List<String>? tags,
    double? price,
    double? rating,
  }) {
    return CaregiverProfile(
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      price: price ?? this.price,
      rating: rating ?? this.rating,
    );
  }

  // Para serializar el objeto a un Map (útil para guardar en bases de datos)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specialty': specialty,
      'description': description,
      'tags': tags,
      'price': price,
      'rating': rating,
    };
  }

  // Para crear un objeto desde un Map (útil para leer de bases de datos)
  factory CaregiverProfile.fromMap(Map<String, dynamic> map) {
    return CaregiverProfile(
      name: map['name'] ?? '',
      specialty: map['specialty'] ?? '',
      description: map['description'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      price: map['price']?.toDouble() ?? 0.0,
      rating: map['rating']?.toDouble() ?? 4.8,
    );
  }

  @override
  String toString() {
    return 'CaregiverProfile(name: $name, specialty: $specialty, price: \$$price/h)';
  }
}