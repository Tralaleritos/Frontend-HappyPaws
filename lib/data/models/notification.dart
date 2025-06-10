import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';


// Modelos de datos
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

class Pet {
  final int id;
  final String name;
  final String type;

  Pet({
    required this.id,
    required this.name,
    required this.type,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

class UserResponse {
  final int id;
  final String username;
  final String? imgUrl;

  UserResponse({
    required this.id,
    required this.username,
    this.imgUrl,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      imgUrl: json['imgUrl'],
    );
  }
}

class OfferResponse {
  final int id;
  final String description;
  final Location location;
  final DateRange range;
  final List<Pet> pets;
  final UserResponse owner;

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
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      location: Location.fromJson(json['location'] ?? {}),
      range: DateRange.fromJson(json['range'] ?? {}),
      pets: (json['pets'] as List<dynamic>?)
          ?.map((pet) => Pet.fromJson(pet))
          .toList() ??
          [],
      owner: UserResponse.fromJson(json['owner'] ?? {}),
    );
  }
}