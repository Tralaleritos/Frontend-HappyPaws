// services/pet_service.dart
import 'dart:convert';
import 'package:happyp/data/models/user.dart';
import 'package:http/http.dart' as http;


class UserService {
  final String _baseUrl = 'http://10.0.2.2:5000/api/v1';
  String? _token;
  void setAuthToken(String token) {
    _token = token;
  }
  Map<String, String> get _headers {
    final baseHeaders = {'Content-Type': 'application/json'};
    if (_token != null) {
      baseHeaders['Authorization'] = 'Bearer $_token';
    }
    return baseHeaders;
  }

  Future<User?> getUser() async {
    final url = Uri.parse('$_baseUrl/users/me');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return User.fromJson(jsonData);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  Future<String?> getUserId() async {
    final user = await getUser();
    return user?.id;
  }

}