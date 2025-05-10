import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;
  List<User> _users = [];

  User? get currentUser => _currentUser;

  Future<void> init() async {
    await _loadUsers();
  }

  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList('users') ?? [];

    _users = usersJson
        .map((userStr) => User.fromJson(jsonDecode(userStr)))
        .toList();

    final currentUserJson = prefs.getString('currentUser');
    if (currentUserJson != null) {
      _currentUser = User.fromJson(jsonDecode(currentUserJson));
      notifyListeners();
    }
  }

  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = _users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList('users', usersJson);
  }

  Future<bool> register(String name, String email, String password, String role) async {
    if (_users.any((user) => user.email == email)) {
      return false;
    }

    late User newUser;
    if (role == 'caregiver') {
      newUser = Caregiver(email: email, password: password, name: name);
    } else if (role == 'pet_owner') {
      newUser = PetOwner(email: email, password: password, name: name);
    } else {
      return false;
    }

    _users.add(newUser);
    await _saveUsers();
    return true;
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = _users.firstWhere(
            (user) => user.email == email && user.password == password,
      );

      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUser', jsonEncode(user.toJson()));

      notifyListeners();
      return true;
    } catch (e) {
      return false; // No se encontró usuario
    }
  }

  Future<void> logout() async {
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUser');

    notifyListeners();
  }

  Future<void> addDefaultUsers() async {
    if (_users.isEmpty) {
      await register('Caregiver Demo', 'care@demo.com', '123456', 'caregiver');
      await register('Pet Owner Demo', 'pet@demo.com', '123456', 'pet_owner');
    }
  }
}