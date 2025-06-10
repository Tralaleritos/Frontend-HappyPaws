// HappyPawsApp.dart
import 'package:flutter/material.dart';
import 'package:happyp/config/navigation/navigation_wrapper.dart';
import 'package:happyp/data/service/auth_service.dart';
import 'package:happyp/screens/auth/login_screen.dart';
import 'package:happyp/screens/auth/register_screen.dart';
import 'package:happyp/screens/views_pet_owner/auth/login/update_password/recovery_password.dart';
import 'package:happyp/screens/views_pet_owner/home/home_screen.dart';
import 'package:happyp/screens/views_pet_owner/message/messages_screen.dart';
import 'package:happyp/screens/views_pet_owner/notificactions/notification_screen.dart';
import 'package:happyp/screens/views_pet_owner/profile/profile_screen.dart';
import 'package:happyp/screens/views_pet_owner/search/search_screen.dart';
import 'package:happyp/screens/views_caregiver/auth/splash.dart';
import 'package:happyp/screens/views_caregiver/home/HomeCaregiverScreen.dart';
import 'package:happyp/screens/views_caregiver/message/MesageCaregiverScreen.dart';
import 'package:happyp/screens/views_caregiver/notificactions/NotificationCaregiverScreen.dart';
import 'package:happyp/screens/views_caregiver/profile/ProfileCaregiverScreen.dart';
import 'package:happyp/screens/views_caregiver/search/SearchCaregiverScreen.dart';
import 'package:provider/provider.dart';
import '../themes/colors/AppColors.dart';
import '../themes/typography/AppTypography.dart';
class HappyPawsApp extends StatelessWidget {
  const HappyPawsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return MaterialApp(
          title: 'Happy Paws',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: AppColors.colorScheme,
            textTheme: AppTypography.textTheme,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          initialRoute: '/splash',
          onGenerateRoute: (settings) {
            final currentRoute = settings.name ?? '/login';
            final args = settings.arguments;

            Widget page;

            // CAMBIO PRINCIPAL: Obtener userType del AuthService
            String userType = 'OWNER'; // valor por defecto

            // Primero verificar si viene en los argumentos
            if (args is Map && args.containsKey('role')) {
              userType = args['role'];
            } else {
              // Si no viene en argumentos, obtenerlo del AuthService
              final currentUser = authService.currentUser;
              if (currentUser != null) {
                // Verificar si el usuario tiene rol de CAREGIVER
                if (currentUser.hasRole('CAREGIVER')) {
                  userType = 'CAREGIVER';
                } else if (currentUser.hasRole('OWNER')) {
                  userType = 'OWNER';
                }
              }
            }

            bool showNavBar = [
              '/home',
              '/search',
              '/messages',
              '/notifications',
              '/profile',
            ].contains(currentRoute) ||
                [
                  '/home-caregiver',
                  '/search-caregiver',
                  '/messages-caregiver',
                  '/notifications-caregiver',
                  '/profile-caregiver',
                ].contains(currentRoute);

            switch (currentRoute) {
              case '/splash':
                page = const SplashScreen(nextScreen: LoginScreen());
                break;
              case '/login':
                page = const LoginScreen();
                break;
              case '/register':
                page = const RegisterScreen();
                break;
              case '/update-password':
                final email = (settings.arguments as String?) ?? '';
                page = RecoveryPassword(email: email);
                break;

            // Pantallas para OWNER
              case '/home':
                page = const HomeScreen();
                break;
              case '/search':
                page = const SearchScreen();
                break;
              case '/messages':
                page = const MessagesScreen();
                break;
              case '/notifications':
                page = const NotificationScreen();
                break;
              case '/profile':
                page = const ProfileScreen();
                break;

            // Pantallas para CAREGIVER
              case '/home-caregiver':
                page = const HomeCaregiverScreen();
                break;
              case '/search-caregiver':
                page = const SearchCaregiverScreen();
                break;
              case '/messages-caregiver':
                page = const MessageCaregiverScreen();
                break;
              case '/notifications-caregiver':
                page = const NotificationCaregiverScreen();
                break;
              case '/profile-caregiver':
                page = const ProfileCaregiverScreen();
                break;

              default:
                page = const LoginScreen();
            }

            return MaterialPageRoute(
              builder: (context) => showNavBar
                  ? NavigationWrapper(
                currentRoute: currentRoute,
                userType: userType,
                child: page,
              )
                  : page,
              settings: settings,
            );
          },
        );
      },
    );
  }
}
