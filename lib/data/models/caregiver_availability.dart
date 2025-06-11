class CaregiverAvailability {
  final int caregiverId;
  final String? locationName;
  final double? locationLatitude;
  final double? locationLongitude;
  final bool isAvailable;

  CaregiverAvailability({
    required this.caregiverId,
    this.locationName,
    this.locationLatitude,
    this.locationLongitude,
    required this.isAvailable,
  });

  factory CaregiverAvailability.fromJson(Map<String, dynamic> json) {
    return CaregiverAvailability(
      caregiverId: json['caregiverId'] ?? 0,
      locationName: json['locationName'],
      locationLatitude: json['locationLatitude']?.toDouble(),
      locationLongitude: json['locationLongitude']?.toDouble(),
      isAvailable: json['isAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caregiverId': caregiverId,
      'locationName': locationName,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'isAvailable': isAvailable,
    };
  }

  CaregiverAvailability copyWith({
    int? caregiverId,
    String? locationName,
    double? locationLatitude,
    double? locationLongitude,
    bool? isAvailable,
  }) {
    return CaregiverAvailability(
      caregiverId: caregiverId ?? this.caregiverId,
      locationName: locationName ?? this.locationName,
      locationLatitude: locationLatitude ?? this.locationLatitude,
      locationLongitude: locationLongitude ?? this.locationLongitude,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}