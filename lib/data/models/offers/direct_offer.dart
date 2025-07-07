class DirectOfferRequest {
  final int ownerId;
  final int caregiverId;
  final String locationName;
  final double locationLatitude;
  final double locationLongitude;
  final String description;
  final String date;
  final String startTime;
  final String endTime;
  final List<int> pets;
  final double price;
  final List<int> services;

  DirectOfferRequest({
    required this.ownerId,
    required this.caregiverId,
    required this.locationName,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.pets,
    required this.price,
    required this.services,
  });

  Map<String, dynamic> toJson() {
    return {
      'ownerId': ownerId,
      'caregiverId': caregiverId,
      'locationName': locationName,
      'locationLatitude': locationLatitude,
      'locationLongitude': locationLongitude,
      'description': description,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'pets': pets,
      'price': price,
      'services': services,
    };
  }
}