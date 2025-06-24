import 'package:happyp/data/models/notifications/user_response.dart';

class Location {
  final String name;
  final double latitude;
  final double longitude;

  Location({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }
}

class DateRange {
  final String date;
  final String startTime;
  final String endTime;

  DateRange({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }
}

class PetNotify {
  final int id;
  final String name;
  final String type;

  PetNotify({
    required this.id,
    required this.name,
    required this.type,
  });

  factory PetNotify.fromJson(Map<String, dynamic> json) {
    return PetNotify(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class OfferResponse {
  final int id;
  final String description;
  final double price;
  final Location location;
  final DateRange range;
  final List<PetNotify> pets;
  final UserResponse owner;

  OfferResponse({
    required this.id,
    required this.description,
    required this.price,
    required this.location,
    required this.range,
    required this.pets,
    required this.owner,
  });

  factory OfferResponse.fromJson(Map<String, dynamic> json) {
    return OfferResponse(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      location: Location.fromJson(json['location'] ?? {}),
      range: DateRange.fromJson(json['range'] ?? {}),
      pets: (json['pets'] as List<dynamic>?)
          ?.map((pet) => PetNotify.fromJson(pet))
          .toList() ??
          [],
      owner: UserResponse.fromJson(json['owner'] ?? {}),
    );
  }
}