import 'package:flutter/material.dart';
import 'config/routes/happyPawsApp.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = AuthService();
  await authService.init();
  await authService.addDefaultUsers(); // Opcional para crear usuarios demo

  runApp(
    ChangeNotifierProvider(
      create: (_) => authService,
      child: const HappyPawsApp(),
    ),
  );
}

