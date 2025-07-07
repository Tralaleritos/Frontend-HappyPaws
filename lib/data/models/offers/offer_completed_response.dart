class OfferCompletedResponse {
  final int offerId;
  final String message;

  OfferCompletedResponse({
    required this.offerId,
    required this.message,
  });

  factory OfferCompletedResponse.fromJson(Map<String, dynamic> json) {
    return OfferCompletedResponse(
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