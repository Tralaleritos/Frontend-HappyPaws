import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/care_request.dart';

class RequestService {
  static const _key = 'requests';

  Future<void> saveRequest(CareRequest request) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getRequests();
    existing.add(request);
    final encoded = existing.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  Future<List<CareRequest>> getRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((s) => CareRequest.fromJson(jsonDecode(s))).toList();
  }

  Future<bool> hasSentRequest(String caregiverName) async {
    final requests = await getRequests();
    return requests.any((r) => r.caregiverName == caregiverName);
  }
}
