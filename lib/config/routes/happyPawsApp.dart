import 'package:flutter/material.dart';
import 'package:happyp/auth/email_code_validation.dart';
import 'package:happyp/screens/views_caregiver/caregiver_profile_form_screen.dart';
import 'package:happyp/screens/views_caregiver/home_caregiver.dart';
import 'package:happyp/screens/views_pet_owners/home_pet_owner.dart';
import 'package:happyp/auth/login_screen.dart';
import 'package:happyp/auth/register_screen.dart';
import 'package:happyp/views_pet_owner/home/home_screen.dart';
import 'package:happyp/views_pet_owner/message/messages_screen.dart';
import 'package:happyp/views_pet_owner/notificactions/notification_screen.dart';
import 'package:happyp/views_pet_owner/profile/profile_screen.dart';
import 'package:happyp/screens/views_pet_owners/search_screen.dart';
import '../themes/colors/AppColors.dart';
import '../themes/typography/AppTypography.dart';

class HappyPawsApp extends StatelessWidget {
  const HappyPawsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Paws',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Usamos los colores definidos en AppColors
        colorScheme: AppColors.colorScheme,
        //tipografia de la clase impl.
        textTheme: AppTypography.textTheme,
        // Estilo de botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, // Verde esmeralda
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // Estilo de la AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        // Estilo de las tarjetas
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      // routes
      initialRoute: '/inicio',
      routes: {
        '/': (context) => const InicioScreen(), // <- Pantalla de login
        '/inicio': (context) => const InicioScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomePetOwner(),
        '/search': (context) => const SearchScreen(),
        '/messages': (context) => const MessagesScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile_caregiver': (context) => const CaregiverProfileFormScreen(),
        '/home_caregiver': (_) => HomeCaregiver(),
        '/home_pet_owner': (context) => const HomeScreen(),
        '/email_code_validation': (_) => EmailCodeValidation(),
      },
    );
  }
}