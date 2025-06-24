class CaregiversNearbyResponse {
  final int id;
  final String userName;
  final String imgUrl;
  final double latitude;
  final double longitude;

  CaregiversNearbyResponse({
    required this.id,
    required this.userName,
    required this.imgUrl,
    required this.latitude,
    required this.longitude,
  });

  factory CaregiversNearbyResponse.fromJson(Map<String, dynamic> json) {
    return CaregiversNearbyResponse(
      id: json['caregiverId'] ?? json['id'] ?? 0, // Priorizar caregiverId del JSON
      userName: json['userName'] ?? '',
      imgUrl: json['imgUrl'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiverId': id, // Incluir ambos para compatibilidad
      'userName': userName,
      'imgUrl': imgUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'CaregiversNearbyResponse{id: $id, userName: $userName, imgUrl: $imgUrl, latitude: $latitude, longitude: $longitude}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CaregiversNearbyResponse && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}