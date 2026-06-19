import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../services/corpus_service.dart';
import '../../services/data_store_service.dart';
import '../../services/profile_service.dart';
import '../../services/shopping_service.dart';
import '../../theme/app_colors.dart';
import 'dish_detail_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  }

  List<DateTime> get _days {
    return List.generate(7, (i) => _weekStart.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DataStoreService>();
    final corpus = context.read<CorpusService>();
    final profile = context.read<ProfileService>().profile;
    final entries = store.mealPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('meal plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7))),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () => setState(() => _weekStart = _weekStart.add(const Duration(days: 7))),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: _days.map((day) {
                return _DayCard(
                  day: day,
                  entries: entries,
                  corpus: corpus,
                  lang: profile.lang,
                  onPick: (slot) async {
                    final id = await _pickRecipe(context);
                    if (id != null) store.setMealPlan(_key(day, slot), id);
                  },
                  onClear: (slot) => store.removeMealPlan(_key(day, slot)),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final ids = entries.values.toList();
                  context.read<ShoppingService>().replaceFromRecipeIds(ids);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to shopping list')));
                },
                icon: const Icon(Icons.shopping_bag),
                label: const Text('export to shopping list'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _key(DateTime day, String slot) {
    return '${day.toIso8601String().split("T").first}.$slot';
  }

  Future<String?> _pickRecipe(BuildContext context) async {
    final corpus = context.read<CorpusService>();
    final saved = context.read<DataStoreService>().savedRecipeIds;
    final recipes = saved.map((id) => corpus.recipeById(id)).whereType<Recipe>().toList();
    if (recipes.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('no saved recipes'),
          content: const Text('Save some recipes first to add them to your meal plan.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ok'))],
        ),
      );
      return null;
    }
    final completer = Completer<String?>();
    await showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('choose a recipe'),
        children: recipes.map((r) => SimpleDialogOption(
          onPressed: () {
            completer.complete(r.id);
            Navigator.pop(ctx);
          },
          child: Text(r.title.text(context.read<ProfileService>().profile.lang)),
        )).toList(),
      ),
    );
    if (!completer.isCompleted) completer.complete(null);
    return completer.future;
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final Map<String, String> entries;
  final CorpusService corpus;
  final String lang;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onClear;
  const _DayCard({
    required this.day,
    required this.entries,
    required this.corpus,
    required this.lang,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d').format(day);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...['breakfast', 'lunch', 'dinner'].map((slot) {
              final key = '${day.toIso8601String().split("T").first}.$slot';
              final recipeId = entries[key];
              final recipe = recipeId != null ? corpus.recipeById(recipeId) : null;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(slot, style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, color: AppColors.inkMuted)),
                title: recipe == null
                    ? const Text('tap to add', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.inkMuted))
                    : Text(recipe.title.text(lang), style: Theme.of(context).textTheme.bodyMedium),
                trailing: recipe == null
                    ? IconButton(icon: const Icon(Icons.add), onPressed: () => onPick(slot))
                    : IconButton(icon: const Icon(Icons.clear), onPressed: () => onClear(slot)),
                onTap: () {
                  if (recipe != null) {
                    final dish = corpus.dishById(recipe.dishId);
                    if (dish != null) Navigator.of(context).push(MaterialPageRoute(builder: (_) => DishDetailScreen(dish: dish)));
                  } else {
                    onPick(slot);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
