class CareRequest {
  final String caregiverName;
  final String petName;
  final String date;
  final String startTime;
  final String endTime;
  final String location;
  final String details;

  CareRequest({
    required this.caregiverName,
    required this.petName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'caregiverName': caregiverName,
      'petName': petName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'details': details,
    };
  }

  factory CareRequest.fromJson(Map<String, dynamic> json) {
    return CareRequest(
      caregiverName: json['caregiverName'],
      petName: json['petName'],
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      location: json['location'],
      details: json['details'],
    );
  }
}
