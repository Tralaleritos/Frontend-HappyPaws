import 'package:happyp/data/models/pet.dart';
import 'package:happyp/data/models/user.dart';

class CreateOfferRequest {
  final int ownerId;
  final LocationModel location;
  final String description;
  final DateRangeModel range;
  final List<Pet> pets;

  CreateOfferRequest({
    required this.ownerId,
    required this.location,
    required this.description,
    required this.range,
    required this.pets,
  });

  Map<String, dynamic> toJson() => {
    'ownerId': ownerId,
    ...location.toJson(),
    'description': description,
    ...range.toJson(),
    'pets': pets.map((pet) => pet.id).toList(),  // Solo enviar IDs
  };
}

class OfferResponse {
  final int id;
  final String description;
  final LocationModel location;
  final DateRangeModel range;
  final List<Pet> pets;
  final User owner;

  OfferResponse({
    required this.id,
    required this.description,
    required this.location,
    required this.range,
    required this.pets,
    required this.owner,
  });

  factory OfferResponse.fromJson(Map<String, dynamic> json) {
    return OfferResponse(
      id: json['id'],
      description: json['description'],
      location: LocationModel.fromJson(json['location']),
      range: DateRangeModel.fromJson(json['range']),
      pets: (json['pets'] as List)
          .map((petJson) => Pet.fromJson(petJson))
          .toList(),
      owner: User.fromJson(json['OWNER']),
    );
  }

  @override
  String toString() {
    return 'OfferResponse(id: $id, description: $description)';
  }
}
class DateRangeModel {
  final String date;
  final String startTime;
  final String endTime;

  DateRangeModel({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
  };

  // Agregar fromJson para poder deserializar la respuesta
  factory DateRangeModel.fromJson(Map<String, dynamic> json) {
    return DateRangeModel(
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }
}
class LocationModel {
  final String name;
  final double latitude;
  final double longitude;

  LocationModel({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'locationName': name,
    'locationLatitude': latitude,
    'locationLongitude': longitude,
  };

  // Agregar fromJson para poder deserializar la respuesta
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }
}