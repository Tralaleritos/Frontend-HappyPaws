import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:happyp/views_pet_owner/auth/login/login_screen.dart';
import 'package:happyp/views_pet_owner/auth/register_screen.dart';
import 'package:happyp/views_pet_owner/home/home_screen.dart';
import 'package:happyp/views_pet_owner/message/messages_screen.dart';
import 'package:happyp/views_pet_owner/notificactions/notification_screen.dart';
import 'package:happyp/views_pet_owner/profile/profile_screen.dart';
import 'package:happyp/views_pet_owner/search/search_screen.dart';
import '../../views_caregiver/auth/login_carigiver_screen.dart';
import '../../views_caregiver/auth/splash.dart';
import '../../views_caregiver/home/HomeCaregiverScreen.dart';
import '../../views_caregiver/message/MesageCaregiverScreen.dart';
import '../../views_caregiver/notificactions/NotificationCaregiverScreen.dart';
import '../../views_caregiver/profile/ProfileCaregiverScreen.dart';
import '../../views_caregiver/search/SearchCaregiverScreen.dart';
import '../../views_pet_owner/auth/login/update_password/recovery_password.dart';
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
        appBarTheme: const AppBarTheme(
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
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        // Verificar la ruta actual
        Widget page;
        String currentRoute = settings.name ?? '/login-duenio';
        bool showNavBar = false;
        String userType = 'dueño'; // Por defecto dueño

        // Identificar el tipo de usuario basado en la ruta
        if (currentRoute.contains('-caregiver') || currentRoute == '/login-cuidador') {
          userType = 'cuidador';
        }

        // Verificar si la ruta actual debe mostrar la barra de navegación personalizada
        if ([
          // Rutas para dueño con navegación
          '/home', '/search', '/messages', '/notifications', '/profile',
          // Rutas para cuidador con navegación
          '/home-caregiver', '/search-caregiver', '/messages-caregiver',
          '/notifications-caregiver', '/profile-caregiver'
        ].contains(currentRoute)) {
          showNavBar = true;
        }

        // Asignar página según la ruta
        switch (currentRoute) {
        // Rutas de autenticación (sin barra de navegación)
          case '/splash':
            page = const SplashScreen(nextScreen: LoginScreen(),);
            break;
          case '/login-duenio':
            page = const LoginScreen();
            break;
          case '/login-cuidador':
            page = const LoginCarigiverScreen();
            break;
          case '/register':
            page = const RegisterScreen();
            break;
          case '/update-password':
            final String email = (settings.arguments as String?) ?? '';
            page = RecoveryPassword(email: email);
            break;

        // Rutas para dueño de mascota
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

        // Rutas para cuidador
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

        // Ruta por defecto
          default:
          // Redireccionar según el tipo de usuario inferido
            if (userType == 'cuidador') {
              page = const LoginCarigiverScreen();
            } else {
              page = const LoginScreen();
            }
        }

        // Envolver la página en un NavigationWrapper si corresponde
        if (showNavBar) {
          return MaterialPageRoute(
            builder: (context) => NavigationWrapper(
              child: page,
              currentRoute: currentRoute,
              userType: userType,
            ),
            settings: settings,
          );
        } else {
          return MaterialPageRoute(
            builder: (context) => page,
            settings: settings,
          );
        }
      },
    );
  }
}

class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String userType;

  const NavigationWrapper({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 30, right: 30, bottom: 10, top: 10),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: userType == 'cuidador'
                    ? AppColors.primary.withBlue(180) // Color ligeramente diferente para cuidadores
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: userType == 'cuidador'
                    ? _buildCaregiverNavItems(context)
                    : _buildOwnerNavItems(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Elementos de navegación para dueños de mascotas
  List<Widget> _buildOwnerNavItems(BuildContext context) {
    return [
      _buildNavItem(
        context: context,
        iconOutline: Icons.home_outlined,
        iconSolid: Icons.home,
        label: 'Inicio',
        isSelected: currentRoute == '/home',
        onTap: () {
          if (currentRoute != '/home') {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
      ),
      _buildNavItem(
        context: context,
        iconOutline: Icons.search_outlined,
        iconSolid: Icons.saved_search,
        label: 'Buscar',
        isSelected: currentRoute == '/search',
        onTap: () {
          if (currentRoute != '/search') {
            Navigator.pushReplacementNamed(context, '/search');
          }
        },
      ),
      _buildNavItem(
        context: context,
        iconOutline: Icons.chat_bubble_outline,
        iconSolid: Icons.chat,
        label: 'Mensajes',
        isSelected: currentRoute == '/messages',
        onTap: () {
          if (currentRoute != '/messages') {
            Navigator.pushReplacementNamed(context, '/messages');
          }
        },
      ),
      _buildNavItem(
        context: context,
        iconOutline: Icons.person_outline,
        iconSolid: Icons.person,
        label: 'Perfil',
        isSelected: currentRoute == '/profile',
        onTap: () {
          if (currentRoute != '/profile') {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
      ),
    ];
  }

  // Elementos de navegación para cuidadores
  List<Widget> _buildCaregiverNavItems(BuildContext context) {
    return [
      _buildNavItem(
        context: context,
        iconOutline: Icons.home_outlined,
        iconSolid: Icons.home,
        label: 'Inicio',
        isSelected: currentRoute == '/home-caregiver',
        onTap: () {
          if (currentRoute != '/home-caregiver') {
            Navigator.pushReplacementNamed(context, '/home-caregiver');
          }
        },
      ),
      _buildNavItem(
        context: context,
        iconOutline: Icons.search_outlined,
        iconSolid: Icons.saved_search,
        label: 'Buscar',
        isSelected: currentRoute == '/search-caregiver',
        onTap: () {
          if (currentRoute != '/search-caregiver') {
            Navigator.pushReplacementNamed(context, '/search-caregiver');
          }
        },
      ),
      _buildNavItem(
        context: context,
        iconOutline: Icons.chat_bubble_outline,
        iconSolid: Icons.chat,
        label: 'Mensajes',
        isSelected: currentRoute == '/messages-caregiver',
        onTap: () {
          if (currentRoute != '/messages-caregiver') {
            Navigator.pushReplacementNamed(context, '/messages-caregiver');
          }
        },
      ),
      _buildNavItem(
        context: context,
        iconOutline: Icons.person_outline,
        iconSolid: Icons.person,
        label: 'Perfil',
        isSelected: currentRoute == '/profile-caregiver',
        onTap: () {
          if (currentRoute != '/profile-caregiver') {
            Navigator.pushReplacementNamed(context, '/profile-caregiver');
          }
        },
      ),
    ];
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData iconOutline,
    required IconData iconSolid,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: isSelected
            ? BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? iconSolid : iconOutline,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 26,
            ),
            // Puedes descomentar esto si deseas mostrar etiquetas de texto
            /*
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            */
          ],
        ),
      ),
    );
  }
}