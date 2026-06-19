import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'home_feed.dart';
import 'cookbook_screen.dart';
import 'search_screen.dart';
import 'meal_plan_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final lang = context.select<AppState, String>((s) => s.profile.lang);
    final items = [
      _NavItem('home', Icons.home_outlined, Icons.home),
      _NavItem('cookbook', Icons.bookmark_border_outlined, Icons.bookmark),
      _NavItem('search', Icons.search, Icons.search),
      _NavItem('plan', Icons.calendar_today_outlined, Icons.calendar_today),
      _NavItem('settings', Icons.person_outline, Icons.person),
    ];
    return Scaffold(
      backgroundColor: MorphColors.paper,
      body: IndexedStack(
        index: _index,
        children: [
          HomeFeed(lang: lang),
          CookbookScreen(lang: lang),
          SearchScreen(lang: lang),
          MealPlanScreen(lang: lang),
          SettingsScreen(lang: lang),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: MorphColors.paper,
          border: Border(top: BorderSide(color: MorphColors.divider, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(items.length, (i) {
                final it = items[i];
                final sel = i == _index;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(sel ? it.active : it.icon, size: 20, color: sel ? MorphColors.coral : MorphColors.inkMuted),
                        const SizedBox(height: 4),
                        Text(it.label, style: MorphFonts.mono(size: 9, color: sel ? MorphColors.ink : MorphColors.inkMuted)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData active;
  const _NavItem(this.label, this.icon, this.active);
}
