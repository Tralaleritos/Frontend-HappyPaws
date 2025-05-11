import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/caregiver_profile.dart';

// Servicio para manejar la persistencia de datos
class DataService {
  static const String _caregiversKey = 'caregivers_data';

  // Singleton pattern
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  // Guarda el perfil de un cuidador
  Future<bool> saveCaregiverProfile(CaregiverProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener perfiles existentes
      List<CaregiverProfile> profiles = await getCaregiverProfiles();

      // Añadir nuevo perfil
      profiles.add(profile);

      // Convertir a lista de mapas
      List<Map<String, dynamic>> profilesMap =
      profiles.map((profile) => profile.toMap()).toList();

      // Guardar como JSON
      await prefs.setString(_caregiversKey, jsonEncode(profilesMap));

      return true;
    } catch (e) {
      print('Error guardando perfil: $e');
      return false;
    }
  }

  // Obtiene todos los perfiles de cuidadores
  Future<List<CaregiverProfile>> getCaregiverProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener string JSON
      String? profilesJson = prefs.getString(_caregiversKey);

      if (profilesJson == null || profilesJson.isEmpty) {
        return [];
      }

      // Decodificar JSON
      List<dynamic> decodedList = jsonDecode(profilesJson);

      // Convertir a lista de objetos CaregiverProfile
      return decodedList
          .map((item) => CaregiverProfile.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Error cargando perfiles: $e');
      return [];
    }
  }

  // Limpiar todos los perfiles (para pruebas)
  Future<bool> clearAllProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_caregiversKey);
      return true;
    } catch (e) {
      print('Error borrando perfiles: $e');
      return false;
    }
  }
}