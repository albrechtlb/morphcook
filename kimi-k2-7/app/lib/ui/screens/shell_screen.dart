import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'cookbook_screen.dart';
import 'home_screen.dart';
import 'meal_plan_screen.dart';
import 'settings_screen.dart';
import 'shopping_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    CookbookScreen(),
    MealPlanScreen(),
    ShoppingScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: AppColors.paper,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.inkMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), label: 'Cookbook'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'More'),
        ],
      ),
    );
  }
}
