import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

class PetService {
  Future<void> savePet(String ownerEmail, Pet pet) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pets_$ownerEmail';

    final List<String> existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode(pet.toJson()));

    await prefs.setStringList(key, existing);
  }

  Future<List<Pet>> getPets(String ownerEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'pets_$ownerEmail';

    final List<String> data = prefs.getStringList(key) ?? [];
    return data.map((jsonStr) => Pet.fromJson(jsonDecode(jsonStr))).toList();
  }

  Future<void> clearPets(String ownerEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pets_$ownerEmail');
  }
}
