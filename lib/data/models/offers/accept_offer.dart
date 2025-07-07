class AcceptOfferRequest {
  final int offerId;
  final int caregiverId;

  AcceptOfferRequest({
    required this.offerId,
    required this.caregiverId,
  });

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'caregiverId': caregiverId,
    };
  }
}