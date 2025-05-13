// lib/widgets/main_navigation_scaffold_alt.dart
import 'package:flutter/material.dart';

class MainNavigationScaffoldAlt extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final PreferredSizeWidget? appBar;

  const MainNavigationScaffoldAlt({
    super.key,
    required this.currentIndex,
    required this.body,
    this.appBar,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home_caregiver');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/appointments');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/notifications_caregiver');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile_caregiver');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box),
            label: 'Cuenta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menú',
          ),
        ],
      ),
    );
  }
}
