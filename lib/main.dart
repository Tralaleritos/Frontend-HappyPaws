import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/routes/happyPawsApp.dart';
import 'data/models/nueva/user_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
      ],
      child: const HappyPawsApp(),
    ),
  );
}


