class OfferUnavailableResponse {
  final int offerId;
  final String message;

  OfferUnavailableResponse({
    required this.offerId,
    required this.message,
  });

  factory OfferUnavailableResponse.fromJson(Map<String, dynamic> json) {
    return OfferUnavailableResponse(
      offerId: json['offerId'] as int,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'message': message,
    };
  }
}