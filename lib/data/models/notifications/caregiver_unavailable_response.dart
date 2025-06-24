class CaregiverUnavailableResponse {
  final int caregiverId;
  final String type;

  CaregiverUnavailableResponse({
    required this.caregiverId,
    required this.type,
  });

  factory CaregiverUnavailableResponse.fromJson(Map<String, dynamic> json) {
    return CaregiverUnavailableResponse(
      caregiverId: json['caregiverId'] ?? 0,
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'caregiverId': caregiverId,
      'type': type,
    };
  }

  @override
  String toString() {
    return 'CaregiverUnavailableResponse{caregiverId: $caregiverId, type: $type}';
  }
}