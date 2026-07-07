import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MealPlanningScreen extends StatefulWidget {
  @override
  _MealPlanningScreenState createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends State<MealPlanningScreen> {
  final List<String> _days = [
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
    'sun'
  ];
  final List<String> _meals = ['breakfast', 'lunch', 'dinner'];
  final Map<String, String> _plan = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      appBar: AppBar(
        title: Text(
          'meal plan',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined),
            onPressed: () {},
            tooltip: 'export to shopping list',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                return _buildMealSection(_meals[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.dashedBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _days.map((day) {
          return Text(
            day,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMealSection(String meal) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.dashedBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal,
            style: GoogleFonts.caveat(fontSize: 24),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _days.map((day) {
              final key = '$day.$meal';
              final recipeId = _plan[key];
              return _buildMealSlot(day, meal, recipeId);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSlot(String day, String meal, String? recipeId) {
    return InkWell(
      onTap: () {
        _showRecipePicker(day, meal);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dashedBorder),
          color: recipeId != null ? AppTheme.stripeCoral.withOpacity(0.2) : null,
        ),
        child: recipeId != null
            ? Icon(Icons.restaurant, size: 16, color: AppTheme.inkBlack)
            : Icon(Icons.add, size: 16, color: AppTheme.dashedBorder),
      ),
    );
  }

  void _showRecipePicker(String day, String meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.paperCream,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'add to $day $meal',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 24),
              ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration:
                      AppTheme.stripedPlaceholder(AppTheme.stripeCoral),
                ),
                title: Text(
                  'Döner Kebab (Vegan)',
                  style: GoogleFonts.jetBrainsMono(fontSize: 14),
                ),
                onTap: () {
                  setState(() {
                    _plan['$day.$meal'] = 'doener-vegan';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration:
                      AppTheme.stripedPlaceholder(AppTheme.stripeGold),
                ),
                title: Text(
                  'Fettuccine Alfredo',
                  style: GoogleFonts.jetBrainsMono(fontSize: 14),
                ),
                onTap: () {
                  setState(() {
                    _plan['$day.$meal'] = 'alfredo-classic';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
