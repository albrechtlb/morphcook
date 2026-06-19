import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/dish.dart';
import '../../models/profile.dart';
import '../../models/recipe.dart';
import '../../services/corpus_service.dart';
import '../../services/data_store_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/matching.dart';
import '../widgets/shared.dart';
import 'cook_mode_screen.dart';

class DishDetailScreen extends StatefulWidget {
  final Dish dish;
  const DishDetailScreen({super.key, required this.dish});

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _selectedRecipe = 0;
  bool _ingredientsExpanded = true;
  bool _methodExpanded = true;

  List<Recipe> get _recipes => context.read<CorpusService>().recipesForDish(widget.dish.id);
  Recipe get current => _recipes.isNotEmpty ? _recipes[_selectedRecipe.clamp(0, _recipes.length - 1)] : _recipes.first;

  @override
  Widget build(BuildContext context) {
    final corpus = context.read<CorpusService>();
    final profile = context.read<ProfileService>().profile;
    final recipes = _recipes;
    if (recipes.isEmpty) {
      return const Scaffold(body: Center(child: Text('No recipes for this dish.')));
    }
    if (_selectedRecipe >= recipes.length) {
      _selectedRecipe = recipes.length - 1;
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.dish.canonicalName.text(profile.lang))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Hero(
            tag: 'dish-${widget.dish.id}',
            child: SizedBox(
              height: 220,
              child: StripedPlaceholder(
                color: widget.dish.stripeColor.toColor(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.dish.heroText.text(profile.lang),
                    style: TextStyle(
                      fontFamily: AppTheme.handFont,
                      fontSize: 26,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.dish.canonicalName.text(profile.lang), style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text(current.subtitle.text(profile.lang), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                _VariantSwitches(
                  recipes: recipes,
                  current: current,
                  onSelect: (recipe) {
                    setState(() => _selectedRecipe = recipes.indexOf(recipe));
                  },
                ),
                const SizedBox(height: 12),
                if (!_isProfileCompatible(current, profile, corpus)) _ConflictNote(profile: profile),
                const DashedDivider(),
                const SizedBox(height: 16),
                _ExpandableSection(
                  title: 'ingredients',
                  expanded: _ingredientsExpanded,
                  onTap: () => setState(() => _ingredientsExpanded = !_ingredientsExpanded),
                  child: _IngredientsList(recipe: current, lang: profile.lang),
                ),
                const SizedBox(height: 16),
                _ExpandableSection(
                  title: 'method',
                  expanded: _methodExpanded,
                  onTap: () => setState(() => _methodExpanded = !_methodExpanded),
                  child: _MethodList(recipe: current, lang: profile.lang),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _ActionBar(recipe: current),
    );
  }

  bool _isProfileCompatible(Recipe recipe, Profile profile, CorpusService corpus) {
    final matcher = RecipeMatcher(ontology: corpus.ontology, ingredientTree: corpus.ingredientTree);
    return matcher.visible(recipe, profile);
  }
}

class _VariantSwitches extends StatelessWidget {
  final List<Recipe> recipes;
  final Recipe current;
  final ValueChanged<Recipe> onSelect;
  const _VariantSwitches({
    required this.recipes,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final diets = recipes.map((r) => r.diet).toSet().toList();
    final efforts = recipes.map((r) => r.effort).toSet().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DimensionRow(
          label: 'diet',
          values: diets,
          selected: current.diet,
          display: (v) => v,
          onTap: (v) => _match(context, diet: v, effort: current.effort),
        ),
        const SizedBox(height: 12),
        _DimensionRow(
          label: 'effort',
          values: efforts,
          selected: current.effort,
          display: (v) => v,
          onTap: (v) => _match(context, diet: current.diet, effort: v),
        ),
        const SizedBox(height: 12),
        _DimensionRow(
          label: 'calories',
          values: recipes.map((r) => r.caloriesPerServing.toString()).toSet().toList(),
          selected: current.caloriesPerServing.toString(),
          display: (v) => '~${v}',
          onTap: (v) => _match(context, diet: current.diet, effort: current.effort, calories: int.tryParse(v) ?? current.caloriesPerServing),
        ),
      ],
    );
  }

  void _match(BuildContext context, {required String diet, required String effort, int? calories}) {
    final target = calories ?? current.caloriesPerServing;
    final candidates = recipes.where((r) => r.diet == diet && r.effort == effort);
    Recipe? best = candidates.isNotEmpty ? candidates.reduce((a, b) =>
        (a.caloriesPerServing - target).abs() < (b.caloriesPerServing - target).abs() ? a : b) : null;
    best ??= recipes.firstWhere(
      (r) => r.diet == diet,
      orElse: () => current,
    );
    onSelect(best);
  }
}

class _DimensionRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selected;
  final String Function(String) display;
  final ValueChanged<String> onTap;
  const _DimensionRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.display,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: AppTheme.handFont, fontSize: 18)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((v) {
            final isSelected = v == selected;
            return ChoiceChip(
              label: Text(display(v)),
              selected: isSelected,
              onSelected: (_) => onTap(v),
              selectedColor: AppColors.ink,
              labelStyle: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 12,
                color: isSelected ? AppColors.paper : AppColors.ink,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ConflictNote extends StatelessWidget {
  final Profile profile;
  const _ConflictNote({required this.profile});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'This version is outside your ${profile.lang == 'de' ? 'Profil' : 'profile'} preferences. Your profile preselects, it never locks.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.coral, fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;
  const _ExpandableSection({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(title, style: Theme.of(context).textTheme.headlineMedium),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            onTap: onTap,
          ),
          if (expanded) child,
        ],
      ),
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final Recipe recipe;
  final String lang;
  const _IngredientsList({required this.recipe, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: ValueKey(recipe.id),
      effects: const [FadeEffect(), SlideEffect(begin: Offset(0.02, 0), end: Offset.zero)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recipe.ingredients.map((ing) {
          final qty = ing.quantity == null || ing.quantity == 0 ? '' : '${_fmt(ing.quantity!)} ';
          final unit = ing.unit ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontFamily: 'PlayfairDisplay', fontStyle: FontStyle.italic)),
                Expanded(
                  child: Text(
                    '$qty$unit ${ing.name.text(lang)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmt(double v) {
    return v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}

class _MethodList extends StatelessWidget {
  final Recipe recipe;
  final String lang;
  const _MethodList({required this.recipe, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: ValueKey(recipe.id),
      effects: const [FadeEffect()],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: recipe.method.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.ink,
                  child: Text('$index', style: const TextStyle(fontSize: 10, color: AppColors.paper, fontFamily: 'JetBrainsMono')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.text.text(lang), style: Theme.of(context).textTheme.bodyMedium),
                      if (step.timerSeconds != null && step.timerSeconds! > 0)
                        TextButton.icon(
                          onPressed: () {
                            // Could start timer
                          },
                          icon: const Icon(Icons.timer, size: 16),
                          label: Text(_formatTime(step.timerSeconds!)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }
}

class _ActionBar extends StatelessWidget {
  final Recipe recipe;
  const _ActionBar({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DataStoreService>();
    final isSaved = store.isSaved(recipe.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'save-${recipe.id}',
            mini: true,
            onPressed: () => store.toggleSaved(recipe.id),
            backgroundColor: AppColors.paperDark,
            child: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'cook-${recipe.id}',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CookModeScreen(recipe: recipe))),
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            icon: const Icon(Icons.local_fire_department),
            label: const Text('cook'),
          ),
        ],
      ),
    );
  }
}
