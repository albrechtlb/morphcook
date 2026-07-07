import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/profile.dart';
import '../../services/profile_service.dart';
import 'shell_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  String _lang = 'en';
  String _name = '';
  Set<String> _dietFlags = {};
  Set<String> _allergies = {};
  int _calorieTarget = 600;
  int _maxTime = 60;
  String _effort = 'medium';

  static const totalPages = 5;

  @override
  Widget build(BuildContext context) {
    final isLast = _page == totalPages - 1;
    return Scaffold(
      appBar: AppBar(
        title: Text('morphcook'),
        leading: _page > 0
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prev)
            : const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_page + 1) / totalPages),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _LangPage(lang: _lang, onChanged: (v) => setState(() => _lang = v)),
                _NamePage(name: _name, onChanged: (v) => setState(() => _name = v)),
                _DietPage(dietFlags: _dietFlags, allergies: _allergies, onDiet: (v) => setState(() => _dietFlags = v), onAllergies: (v) => setState(() => _allergies = v)),
                _BudgetPage(calories: _calorieTarget, time: _maxTime, effort: _effort, onChanged: (c, t, e) => setState(() {
                  _calorieTarget = c;
                  _maxTime = t;
                  _effort = e;
                })),
                _ConfirmPage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextOrFinish,
                child: Text(isLast ? 'start cooking' : 'continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _prev() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _nextOrFinish() async {
    if (_page < totalPages - 1) {
      _next();
    } else {
      final profile = Profile(
        name: _name,
        lang: _lang,
        avoidFlags: {..._dietFlags, ..._allergies},
        calorieTarget: _calorieTarget,
        maxTimeMinutes: _maxTime,
        preferredEffort: _effort,
      );
      final service = context.read<ProfileService>();
      await service.saveProfile(profile);
      await service.setOnboarded(true);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ShellScreen()));
      }
    }
  }
}

class _LangPage extends StatelessWidget {
  final String lang;
  final ValueChanged<String> onChanged;
  const _LangPage({required this.lang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'language',
      subtitle: 'Choose your language',
      child: Column(
        children: [
          _Choice(value: 'en', label: 'English', selected: lang, onChanged: onChanged),
          _Choice(value: 'de', label: 'Deutsch', selected: lang, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final String name;
  final ValueChanged<String> onChanged;
  const _NamePage({required this.name, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'what should we call you?',
      subtitle: 'This helps us make the app feel personal.',
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'your name',
          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _DietPage extends StatelessWidget {
  final Set<String> dietFlags;
  final Set<String> allergies;
  final ValueChanged<Set<String>> onDiet;
  final ValueChanged<Set<String>> onAllergies;
  const _DietPage({required this.dietFlags, required this.allergies, required this.onDiet, required this.onAllergies});

  @override
  Widget build(BuildContext context) {
    final options = ['vegan', 'vegetarian', 'pescatarian', 'halal', 'kosher', 'lactose-free', 'gluten-free'];
    final allergyOptions = ['peanuts', 'tree-nuts', 'soy', 'shellfish', 'fish', 'egg', 'dairy', 'sesame'];
    return _Page(
      title: 'how do you eat?',
      subtitle: 'Select all that apply.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('diet', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: Theme.of(context).disabledColor)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((v) => FilterChip(
              label: Text(v),
              selected: dietFlags.contains(v),
              onSelected: (s) {
                final next = {...dietFlags};
                if (s) next.add(v); else next.remove(v);
                onDiet(next);
              },
            )).toList(),
          ),
          const SizedBox(height: 24),
          Text('allergies', style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: Theme.of(context).disabledColor)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergyOptions.map((v) => FilterChip(
              label: Text(v),
              selected: allergies.contains(v),
              onSelected: (s) {
                final next = {...allergies};
                if (s) next.add(v); else next.remove(v);
                onAllergies(next);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _BudgetPage extends StatelessWidget {
  final int calories;
  final int time;
  final String effort;
  final void Function(int, int, String) onChanged;
  const _BudgetPage({required this.calories, required this.time, required this.effort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'today\'s mood',
      subtitle: 'You can change this anytime.',
      child: Column(
        children: [
          ListTile(
            title: Text('calorie target'),
            trailing: Text('$calories kcal'),
          ),
          Slider(
            value: calories.toDouble(),
            min: 200,
            max: 1200,
            divisions: 10,
            label: '$calories',
            onChanged: (v) => onChanged(v.toInt(), time, effort),
          ),
          ListTile(
            title: Text('time budget'),
            trailing: Text('$time min'),
          ),
          Slider(
            value: time.toDouble(),
            min: 15,
            max: 120,
            divisions: 7,
            label: '$time',
            onChanged: (v) => onChanged(calories, v.toInt(), effort),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['easy', 'medium', 'hard'].map((v) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(v),
                selected: effort == v,
                onSelected: (_) => onChanged(calories, time, v),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ConfirmPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'we\'re set',
      subtitle: 'Your cookbook is ready. You can change these in settings.',
      child: Center(
        child: Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  final String value;
  final String label;
  final String selected;
  final ValueChanged<String> onChanged;
  const _Choice({required this.value, required this.label, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return ListTile(
      selected: active,
      title: Text(label),
      trailing: active ? const Icon(Icons.check) : null,
      onTap: () => onChanged(value),
    );
  }
}

class _Page extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _Page({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }
}
