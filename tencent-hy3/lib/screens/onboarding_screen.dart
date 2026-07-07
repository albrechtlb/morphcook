import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/profile.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final Profile _profile = Profile();

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      _LanguagePage(onLanguageSelected: (lang) {
        _profile.lang = lang;
      }),
      _NamePage(onNameEntered: (name) {
        _profile.name = name;
      }),
      _DietPage(profile: _profile),
      _PreferencesPage(profile: _profile),
      _ConfirmPage(profile: _profile),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.paperCream,
        border: Border(top: BorderSide(color: AppTheme.dashedBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text('< back'),
            )
          else
            SizedBox(width: 80),
          Row(
            children: List.generate(_pages.length, (index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppTheme.inkBlack
                      : AppTheme.dashedBorder,
                ),
              );
            }),
          ),
          if (_currentPage < _pages.length - 1)
            TextButton(
              onPressed: () {
                _pageController.nextPage(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text('next >'),
            )
          else
            ElevatedButton(
              onPressed: () {
                // Complete onboarding
              },
              child: Text('Start Cooking'),
            ),
        ],
      ),
    );
  }
}

class _LanguagePage extends StatelessWidget {
  final Function(String) onLanguageSelected;

  _LanguagePage({required this.onLanguageSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MorphCook',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          SizedBox(height: 16),
          Text(
            'choose your language',
            style: GoogleFonts.caveat(
              fontSize: 28,
              color: AppTheme.inkBlack,
            ),
          ),
          SizedBox(height: 48),
          Row(
            children: [
              _LanguageButton(
                label: 'EN',
                onTap: () => onLanguageSelected('en'),
              ),
              SizedBox(width: 16),
              _LanguageButton(
                label: 'DE',
                onTap: () => onLanguageSelected('de'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  _LanguageButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: AppTheme.polaroidCard,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final Function(String) onNameEntered;

  _NamePage({required this.onNameEntered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'what should we call you?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 48),
          TextField(
            onChanged: onNameEntered,
            style: GoogleFonts.jetBrainsMono(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'your name',
              hintStyle: GoogleFonts.jetBrainsMono(
                color: AppTheme.dashedBorder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DietPage extends StatefulWidget {
  final Profile profile;

  _DietPage({required this.profile});

  @override
  __DietPageState createState() => __DietPageState();
}

class __DietPageState extends State<_DietPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'dietary needs',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          Text(
            'select all that apply',
            style: GoogleFonts.caveat(fontSize: 20),
          ),
          SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildChip('vegan', 'Vegan'),
              _buildChip('vegetarian', 'Vegetarian'),
              _buildChip('pescatarian', 'Pescatarian'),
              _buildChip('halal', 'Halal'),
              _buildChip('kosher', 'Kosher'),
              _buildChip('gluten-free', 'Gluten-Free'),
              _buildChip('dairy-free', 'Dairy-Free'),
              _buildChip('nut-free', 'Nut-Free'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String flag, String label) {
    final isSelected = widget.profile.avoidFlags.contains(flag);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            widget.profile.avoidFlags.add(flag);
          } else {
            widget.profile.avoidFlags.remove(flag);
          }
        });
      },
    );
  }
}

class _PreferencesPage extends StatelessWidget {
  final Profile profile;

  _PreferencesPage({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'your preferences',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 48),
          Text('Calorie target per meal', style: GoogleFonts.jetBrainsMono()),
          Slider(
            value: profile.calorieTarget.toDouble(),
            min: 200,
            max: 1200,
            divisions: 10,
            label: profile.calorieTarget.toString(),
            onChanged: (value) {
              profile.calorieTarget = value.round();
            },
          ),
          SizedBox(height: 32),
          Text('Max cooking time', style: GoogleFonts.jetBrainsMono()),
          Slider(
            value: profile.maxTimeMinutes.toDouble(),
            min: 15,
            max: 120,
            divisions: 7,
            label: '${profile.maxTimeMinutes} min',
            onChanged: (value) {
              profile.maxTimeMinutes = value.round();
            },
          ),
        ],
      ),
    );
  }
}

class _ConfirmPage extends StatelessWidget {
  final Profile profile;

  _ConfirmPage({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'all set, ${profile.name}!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 32),
          Text(
            'Your cookbook is ready.',
            style: GoogleFonts.caveat(fontSize: 24),
          ),
          SizedBox(height: 48),
          Container(
            padding: EdgeInsets.all(24),
            decoration: AppTheme.paperGrainDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diet: ${profile.avoidFlags.join(", ")}',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                SizedBox(height: 8),
                Text('Calories: ${profile.calorieTarget} per meal',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                SizedBox(height: 8),
                Text('Time: ≤ ${profile.maxTimeMinutes} min',
                    style: GoogleFonts.jetBrainsMono(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
