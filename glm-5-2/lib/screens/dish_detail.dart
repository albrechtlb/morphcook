import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/matching.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cook_mode.dart';
import 'ingredient_info_sheet.dart';

class DishDetailScreen extends StatefulWidget {
  final String dishId;
  final String lang;
  final String? initialRecipeId;
  const DishDetailScreen({super.key, required this.dishId, required this.lang, this.initialRecipeId});

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  String? _selectedRecipeId;
  String? _overrideEffort;
  String? _overrideDiet;
  String? _overrideCal;

  @override
  void initState() {
    super.initState();
    _selectedRecipeId = widget.initialRecipeId;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final dish = app.corpus.dishIndex[widget.dishId];
    if (dish == null) {
      return Scaffold(backgroundColor: MorphColors.paper, body: const Center(child: Text('dish not found')));
    }
    final allVariants = dish.variantRecipeIds.map((id) => app.corpus.recipeIndex[id]).whereType<Recipe>().toList();

    // pick default selected
    if (_selectedRecipeId == null || !allVariants.any((r) => r.id == _selectedRecipeId)) {
      final best = app.bestVariantFor(dish) ?? allVariants.firstOrNull;
      _selectedRecipeId = best?.id;
    }
    final selected = _selectedRecipeId == null ? null : app.corpus.recipeIndex[_selectedRecipeId!];
    if (selected == null) {
      return Scaffold(backgroundColor: MorphColors.paper, body: const Center(child: Text('no variant available')));
    }

    // dimensions
    final diets = _uniqueValues(allVariants, (r) => r.diet);
    final efforts = _uniqueValues(allVariants, (r) => r.effort);
    final cals = _uniqueValues(allVariants, (r) => r.calorieLevel);
    final extras = _uniqueExtras(allVariants);

    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(
        title: ltr(dish.canonicalName, widget.lang),
        eyebrow: 'dish',
        actions: [
          SaveButton(recipeId: selected.id),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: MorphColors.coral, size: 22),
            onPressed: () => _openCookMode(context, selected.id),
            tooltip: 'cook',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StripedPlaceholder(
              stripeColorHex: dish.stripeColor,
              caption: ltr(dish.capCaption, widget.lang),
              lang: widget.lang,
              height: 220,
            ),
            const SizedBox(height: 12),
            Text(ltr(dish.heroText, widget.lang), style: MorphFonts.serif(size: 16, color: MorphColors.inkSoft)),
            const SizedBox(height: 6),
            HistoryPill(recipeId: selected.id),
            const SizedBox(height: 16),
            const DashedRule(),
            const SizedBox(height: 16),
            // variant switchers
            _SwitcherRow(
              label: 'diet',
              current: selected.diet,
              options: diets,
              selected: selected.diet,
              variants: allVariants,
              currentRecipe: selected,
              matchDim: (r) => r.diet,
              lang: widget.lang,
              app: app,
              onPick: (v) => setState(() {
                _overrideDiet = v;
                _reselect(allVariants, app);
              }),
            ),
            _SwitcherRow(
              label: 'effort',
              current: selected.effort,
              options: efforts,
              selected: selected.effort,
              variants: allVariants,
              currentRecipe: selected,
              matchDim: (r) => r.effort,
              lang: widget.lang,
              app: app,
              onPick: (v) => setState(() {
                _overrideEffort = v;
                _reselect(allVariants, app);
              }),
            ),
            _SwitcherRow(
              label: 'calorie level',
              current: '~${selected.caloriesPerServing}',
              options: cals,
              selected: selected.calorieLevel,
              variants: allVariants,
              currentRecipe: selected,
              matchDim: (r) => r.calorieLevel,
              lang: widget.lang,
              app: app,
              onPick: (v) => setState(() {
                _overrideCal = v;
                _reselect(allVariants, app);
              }),
            ),
            if (extras.isNotEmpty)
              _SwitcherRow(
                label: 'extras',
                current: selected.extraTags.isEmpty ? 'core' : selected.extraTags.join(','),
                options: ['core', ...extras],
                selected: selected.extraTags.isEmpty ? 'core' : selected.extraTags.first,
                variants: allVariants,
                currentRecipe: selected,
                matchDim: (r) => r.extraTags.isEmpty ? 'core' : r.extraTags.first,
                lang: widget.lang,
                app: app,
                onPick: (v) => setState(() => _reselect(allVariants, app, preferExtra: v == 'core' ? null : v)),
              ),
            const SizedBox(height: 20),
            const DashedRule(),
            const SizedBox(height: 16),
            // conflict note if any
            _ConflictNote(recipe: selected, app: app, lang: widget.lang),
            const SizedBox(height: 16),
            // ingredients / method / macros tabs
            _RecipeBody(recipe: selected, lang: widget.lang, app: app),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openCookMode(context, selected.id),
              style: FilledButton.styleFrom(
                backgroundColor: MorphColors.ink,
                foregroundColor: MorphColors.paper,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              icon: const Icon(Icons.local_fire_department_outlined, size: 18),
              label: Text('start cooking', style: MorphFonts.mono(size: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _reselect(List<Recipe> variants, AppState app, {String? preferExtra}) {
    final current = app.corpus.recipeIndex[_selectedRecipeId!];
    final candidates = variants.where((r) {
      if (_overrideDiet != null && r.diet != _overrideDiet) return false;
      if (_overrideEffort != null && r.effort != _overrideEffort) return false;
      if (_overrideCal != null && r.calorieLevel != _overrideCal) return false;
      if (preferExtra != null) {
        if (preferExtra == 'core' && r.extraTags.isNotEmpty) return false;
        if (preferExtra != 'core' && !r.extraTags.contains(preferExtra)) return false;
      } else if (current != null) {
        // preserve extra-ness unless explicitly overridden
        if (r.extraTags.length != current.extraTags.length) {
          // allow both core or matching extras
          if (r.extraTags.isEmpty && current.extraTags.isEmpty) {
            // ok
          } else if (r.extraTags.any((e) => current.extraTags.contains(e))) {
            // ok
          } else {
            return false;
          }
        }
      }
      return true;
    }).toList();
    Recipe? next;
    if (candidates.isNotEmpty) {
      next = pickBestVariant(candidates, app.profile, app.corpus.ontology, now: DateTime.now(), lastCookedLookup: app.lastCookedAt) ?? candidates.first;
    } else {
      next = variants.firstWhere(
        (r) =>
            (_overrideDiet == null || r.diet == _overrideDiet) &&
            (_overrideEffort == null || r.effort == _overrideEffort) &&
            (_overrideCal == null || r.calorieLevel == _overrideCal),
        orElse: () => variants.first,
      );
    }
    setState(() => _selectedRecipeId = next!.id);
  }

  List<String> _uniqueValues(List<Recipe> variants, String Function(Recipe) getter) {
    final seen = <String>[];
    for (final r in variants) {
      final v = getter(r);
      if (!seen.contains(v)) seen.add(v);
    }
    return seen;
  }

  List<String> _uniqueExtras(List<Recipe> variants) {
    final s = <String>{};
    for (final r in variants) {
      s.addAll(r.extraTags);
    }
    return s.toList();
  }

  void _openCookMode(BuildContext context, String recipeId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CookModeScreen(recipeId: recipeId, lang: widget.lang),
      fullscreenDialog: true,
    ));
  }
}

class _SwitcherRow extends StatefulWidget {
  final String label;
  final String current;
  final List<String> options;
  final String selected;
  final List<Recipe> variants;
  final Recipe currentRecipe;
  final String Function(Recipe) matchDim;
  final String lang;
  final AppState app;
  final void Function(String) onPick;

  const _SwitcherRow({
    required this.label,
    required this.current,
    required this.options,
    required this.selected,
    required this.variants,
    required this.currentRecipe,
    required this.matchDim,
    required this.lang,
    required this.app,
    required this.onPick,
  });

  @override
  State<_SwitcherRow> createState() => _SwitcherRowState();
}

class _SwitcherRowState extends State<_SwitcherRow> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.app.profile;
    // For each option: does it produce a recipe? Does that recipe pass the profile?
    final optionMeta = <String, ({bool exists, bool muted, String? note})>{};
    for (final opt in widget.options) {
      final matches = widget.variants.where((r) => widget.matchDim(r) == opt).toList();
      if (matches.isEmpty) {
        optionMeta[opt] = (exists: false, muted: true, note: 'not written yet');
      } else {
        final allConflict = matches.every((r) => !matchRecipe(r, profile, widget.app.corpus.ontology).visible);
        optionMeta[opt] = (exists: true, muted: allConflict, note: null);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Row(
              children: [
                Text('— ${widget.label} —', style: MorphFonts.label(size: 11, color: MorphColors.inkMuted)),
                const Spacer(),
                Text(widget.current, style: MorphFonts.serif(size: 16, color: MorphColors.ink)),
                const SizedBox(width: 6),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, color: MorphColors.inkMuted, size: 18),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.map((opt) {
                final meta = optionMeta[opt]!;
                return MorphChip(
                  label: opt,
                  selected: widget.selected == opt,
                  muted: meta.muted,
                  disabled: !meta.exists,
                  note: meta.note,
                  onTap: () {
                    if (meta.exists) widget.onPick(opt);
                  },
                );
              }).toList(),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: -0.1, end: 0),
          ],
        ],
      ),
    );
  }
}

class _ConflictNote extends StatelessWidget {
  final Recipe recipe;
  final AppState app;
  final String lang;
  const _ConflictNote({required this.recipe, required this.app, required this.lang});

  @override
  Widget build(BuildContext context) {
    final m = matchRecipe(recipe, app.profile, app.corpus.ontology);
    if (m.visible) return const SizedBox.shrink();
    final reasons = <String>[];
    if (m.conflictFlags.isNotEmpty) reasons.add('contains: ${m.conflictFlags.join(', ')} (in your avoid list)');
    if (m.conflictIngredients.isNotEmpty) reasons.add('contains avoided ingredient(s): ${m.conflictIngredients.join(', ')}');
    if (recipe.timeMinutes > app.profile.maxTimeMinutes && app.profile.timeHardFilter) {
      reasons.add('longer than your ${app.profile.maxTimeMinutes}min budget');
    }
    final calDiff = (recipe.caloriesPerServing - app.profile.calorieTarget).abs();
    if (calDiff > app.profile.calorieTolerance && app.profile.calorieHardFilter) {
      reasons.add('outside your calorie target by ${calDiff - app.profile.calorieTolerance}kcal');
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: MorphColors.coralSoft, width: 1), color: MorphColors.coral.withOpacity(0.06)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: MorphColors.coral, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'this variant sits outside your profile: ${reasons.join('; ')}. you can still cook it — the profile preselects, never locks.',
              style: MorphFonts.mono(size: 10, color: MorphColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeBody extends StatelessWidget {
  final Recipe recipe;
  final String lang;
  final AppState app;
  const _RecipeBody({required this.recipe, required this.lang, required this.app});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            labelColor: MorphColors.ink,
            unselectedLabelColor: MorphColors.inkMuted,
            indicatorColor: MorphColors.coral,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: MorphFonts.mono(size: 12),
            tabs: const [Tab(text: 'ingredients'), Tab(text: 'method'), Tab(text: 'macros')],
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              children: [
                _ingredients(context),
                _method(),
                _macros(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredients(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: recipe.ingredients.length,
      separatorBuilder: (_, __) => const Divider(color: MorphColors.divider, height: 1),
      itemBuilder: (context, i) {
        final ing = recipe.ingredients[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ltr(ing.name, lang), style: MorphFonts.serif(size: 15)),
                    const SizedBox(height: 2),
                    Text(ing.aisle, style: MorphFonts.mono(size: 9, color: MorphColors.inkMuted)),
                  ],
                ),
              ),
              Text('${_fmtQty(ing.quantity)} ${ing.unit}', style: MorphFonts.mono(size: 11, color: MorphColors.inkSoft)),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 14, color: MorphColors.teal),
                onPressed: () => _showGuide(context, ing.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'learn more',
              ),
            ],
          ),
        ).animate(key: ValueKey(ing.id)).fadeIn(duration: 300.ms);
      },
    );
  }

  Widget _method() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: recipe.steps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = recipe.steps[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${s.n}.', style: MorphFonts.display(size: 22, color: MorphColors.coral)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ltr(s.text, lang), style: MorphFonts.serif(size: 15)),
                  if (s.timerSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('~${(s.timerSeconds / 60).round()} min', style: MorphFonts.mono(size: 10, color: MorphColors.teal)),
                    ),
                ],
              ),
            ),
          ],
        ).animate(key: ValueKey(s.n)).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _macros() {
    final macros = recipe.macros;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MacroRow('calories', '${recipe.caloriesPerServing} kcal'),
          _MacroRow('protein', '${macros['protein'] ?? 0} g'),
          _MacroRow('carbs', '${macros['carbs'] ?? 0} g'),
          _MacroRow('fat', '${macros['fat'] ?? 0} g'),
          const SizedBox(height: 12),
          _MacroRow('time', '${recipe.timeMinutes} min'),
          _MacroRow('effort', recipe.effort),
          _MacroRow('servings', '${recipe.servings}'),
          _MacroRow('technique', recipe.techniques.join(', ')),
          const SizedBox(height: 16),
          Text('contains', style: MorphFonts.label(size: 11)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: recipe.contains.map((c) => MorphChip(label: c, selected: false)).toList(),
          ),
        ],
      ),
    );
  }

  void _showGuide(BuildContext context, String ingredientId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MorphColors.paper,
      builder: (_) => IngredientInfoSheet(ingredientId: ingredientId, lang: lang, app: app),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String k;
  final String v;
  const _MacroRow(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(k, style: MorphFonts.mono(size: 11, color: MorphColors.inkMuted))),
          Text(v, style: MorphFonts.serif(size: 15)),
        ],
      ),
    );
  }
}

String _fmtQty(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}
