import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  final List<Map<String, dynamic>> navItems = const [
    {'icon': Icons.home_rounded, 'label': 'Home', 'index': 0},
    {'icon': Icons.connect_without_contact_rounded, 'label': 'Translate', 'index': 1},
    {'icon': Icons.menu_book_rounded, 'label': 'Dictionary', 'index': 2},
    {'icon': Icons.school_rounded, 'label': 'Learn', 'index': 3},
    {'icon': Icons.person_rounded, 'label': 'Profile', 'index': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: AppColors.darkText.withAlpha(0x33),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onItemSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.primary,
          selectedItemColor: AppColors.action,
          selectedIconTheme: const IconThemeData(size: 28),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedItemColor: AppColors.lightText.withAlpha(0xAA),
          unselectedIconTheme: const IconThemeData(size: 24),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }
}
