import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/dish.dart';
import 'dish_detail_screen.dart';
import 'cookbook_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeFeed(),
    CookbookScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: _selectedIndex == 0
          ? _buildHomeAppBar()
          : _buildRegularAppBar(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.paperCream,
        selectedItemColor: AppTheme.inkBlack,
        unselectedItemColor: AppTheme.dashedBorder,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Cookbook'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  AppBar _buildHomeAppBar() {
    return AppBar(
      title: Row(
        children: [
          Text(
            'MorphCook',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    );
  }

  AppBar _buildRegularAppBar() {
    final titles = ['', 'Cookbook', 'Search', 'Profile'];
    return AppBar(
      title: Text(
        titles[_selectedIndex],
        style: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class HomeFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildMasthead(context),
        ),
        SliverToBoxAdapter(
          child: _buildFeaturedDish(context),
        ),
        SliverToBoxAdapter(
          child: _buildSectionHeader(context, 'popular this week'),
        ),
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildDishCard(context, index),
            childCount: 6,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '— more soon —',
              textAlign: TextAlign.center,
              style: GoogleFonts.caveat(
                fontSize: 20,
                color: AppTheme.dashedBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasthead(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'your cookbook,',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'your recipes,',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'your way.',
            style: GoogleFonts.playfairDisplay(
              fontSize: 48,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'every dish, every diet, every time.',
            style: GoogleFonts.caveat(
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDish(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(24),
      decoration: AppTheme.polaroidCard,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DishDetailScreen(dishId: 'doener'),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: AppTheme.stripedPlaceholder(AppTheme.stripeCoral),
              child: Center(
                child: Text(
                  'Döner Kebab',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.inkBlack,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The street food classic, reimagined',
                    style: GoogleFonts.caveat(fontSize: 20),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Berlin\'s favorite midnight snack',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildDishCard(BuildContext context, int index) {
    final dishes = ['doener', 'alfredo', 'pad-thai'];
    final colors = [AppTheme.stripeCoral, AppTheme.stripeGold, AppTheme.stripeRose];
    final dishId = dishes[index % dishes.length];
    final color = colors[index % colors.length];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: AppTheme.polaroidCard,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DishDetailScreen(dishId: dishId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: AppTheme.stripedPlaceholder(color),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                dishId == 'doener'
                    ? 'Döner Kebab'
                    : dishId == 'alfredo'
                        ? 'Fettuccine Alfredo'
                        : 'Pad Thai',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CookbookScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'your saved recipes',
        style: GoogleFonts.caveat(fontSize: 24),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'search recipes',
        style: GoogleFonts.caveat(fontSize: 24),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'profile & settings',
        style: GoogleFonts.caveat(fontSize: 24),
      ),
    );
  }
}
