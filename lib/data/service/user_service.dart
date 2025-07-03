import 'dart:convert';
import 'package:happyp/core/constants/ApiConstants.dart';
import 'package:happyp/data/models/user/user.dart';
import 'package:http/http.dart' as http;

class UserService {
  final String _baseUrl = ApiConstants.BASE_URL; // 👈 Usar constante
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