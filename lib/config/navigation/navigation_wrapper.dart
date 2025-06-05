import 'package:flutter/material.dart';
import '../themes/colors/AppColors.dart';

class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String userType; // 'OWNER' o 'CAREGIVER'

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
          _buildBottomNavigationBar(context),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final isCaregiver = userType == 'CAREGIVER';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isCaregiver
              ? AppColors.primary.withBlue(180)
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
          children: isCaregiver
              ? _buildCaregiverNavItems(context)
              : _buildOwnerNavItems(context),
        ),
      ),
    );
  }

  // Navegación para DUEÑOS
  List<Widget> _buildOwnerNavItems(BuildContext context) {
    return [
      _navItem(
        context,
        iconOutline: Icons.home_outlined,
        iconSolid: Icons.home,
        label: 'Inicio',
        targetRoute: '/home',
      ),
      _navItem(
        context,
        iconOutline: Icons.search_outlined,
        iconSolid: Icons.saved_search,
        label: 'Buscar',
        targetRoute: '/search',
      ),
      _navItem(
        context,
        iconOutline: Icons.chat_bubble_outline,
        iconSolid: Icons.chat,
        label: 'Mensajes',
        targetRoute: '/messages',
      ),
      _navItem(
        context,
        iconOutline: Icons.person_outline,
        iconSolid: Icons.person,
        label: 'Perfil',
        targetRoute: '/profile',
      ),
    ];
  }

  // Navegación para CUIDADORES
  List<Widget> _buildCaregiverNavItems(BuildContext context) {
    return [
      _navItem(
        context,
        iconOutline: Icons.home_outlined,
        iconSolid: Icons.home,
        label: 'Inicio',
        targetRoute: '/home-caregiver',
      ),
      _navItem(
        context,
        iconOutline: Icons.search_outlined,
        iconSolid: Icons.saved_search,
        label: 'Buscar',
        targetRoute: '/search-caregiver',
      ),
      _navItem(
        context,
        iconOutline: Icons.chat_bubble_outline,
        iconSolid: Icons.chat,
        label: 'Mensajes',
        targetRoute: '/messages-caregiver',
      ),
      _navItem(
        context,
        iconOutline: Icons.person_outline,
        iconSolid: Icons.person,
        label: 'Perfil',
        targetRoute: '/profile-caregiver',
      ),
    ];
  }

  Widget _navItem(
      BuildContext context, {
        required IconData iconOutline,
        required IconData iconSolid,
        required String label,
        required String targetRoute,
      }) {
    final isSelected = currentRoute == targetRoute;

    return InkWell(
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, targetRoute);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: isSelected
            ? BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        )
            : null,
        child: Icon(
          isSelected ? iconSolid : iconOutline,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
          size: 26,
        ),
      ),
    );
  }
}
