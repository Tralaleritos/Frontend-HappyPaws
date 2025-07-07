// Alternativa más robusta con manejo de valores por defecto:
class OfferAcceptedResponse {
  final int offerId;
  final int caregiverId;
  final String caregiverName;
  final String caregiverImgUrl;

  OfferAcceptedResponse({
    required this.offerId,
    required this.caregiverId,
    required this.caregiverName,
    required this.caregiverImgUrl,
  });

  factory OfferAcceptedResponse.fromJson(Map<String, dynamic> json) {
    final caregiver = json['caregiver'];
    return OfferAcceptedResponse(
      offerId: json['offerId'] as int,
      caregiverId: caregiver['id'] as int,
      caregiverName: caregiver['username'] as String,
      caregiverImgUrl: caregiver['imgUrl'] as String? ?? '', // ✅ Valor por defecto si es null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'caregiverImgUrl': caregiverImgUrl,
    };
  }
}