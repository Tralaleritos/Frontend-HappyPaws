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