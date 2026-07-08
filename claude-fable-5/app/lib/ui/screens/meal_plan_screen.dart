import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_state.dart';
import '../../models/collections.dart';
import '../../models/recipe.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/decor.dart';
import '../widgets/recipe_row.dart';
import 'search_screen.dart';
import 'shopping_list_screen.dart';

/// Weekly meal plan: Mon–Sun × breakfast/lunch/dinner. Tap a slot to assign
/// from cookbook/search, long-press-drag between slots, one-tap export of
/// the week to the shopping list. Weekly pagination, ±4 weeks window.
///
/// Meal-prep aware: cooking a multi-serving recipe offers to spread the
/// leftover portions over the following free lunch/dinner slots within the
/// recipe's fridge life. Leftover slots are eaten, not cooked — they carry
/// a badge, warn when they outlive the fridge life, and stay off the
/// shopping-list export.
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  /// Offset in weeks from the current week (clamped to ±4 — the spec's
  /// "max 4 weeks rendered" guardrail, one week rendered at a time).
  int _weekOffset = 0;

  DateTime get _weekDate =>
      weekStart(DateTime.now()).add(Duration(days: 7 * _weekOffset));

  String get _weekKey => isoWeekKey(_weekDate);

  @override
  void initState() {
    super.initState();
    _preloadWeek();
  }

  /// Persisted plans can reference recipes in not-yet-loaded partitions;
  /// pull them in so titles and calorie sums render.
  Future<void> _preloadWeek() async {
    final state = context.read<AppState>();
    final week = state.mealPlan[_weekKey];
    if (week == null) return;
    var loadedAny = false;
    for (final entry in week.values) {
      final id = plannedRecipeId(entry);
      if (state.corpus.loadedRecipeById(id) == null) {
        await state.corpus.recipeById(id);
        loadedAny = true;
      }
    }
    if (loadedAny && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = S(state.lang);
    final week = state.mealPlan[_weekKey] ?? const <String, String>{};

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(s('mealPlan'),
                    style: MorphText.display.copyWith(fontSize: 30)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.shopping_basket_outlined,
                      size: 20, color: MorphColors.inkSoft),
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ShoppingListScreen())),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: _weekOffset > -4
                      ? () => setState(() {
                            _weekOffset--;
                            _preloadWeek();
                          })
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 20),
                ),
                Expanded(
                  child: Center(
                    child: Text('${s('week')} $_weekKey'.toLowerCase(),
                        style: MorphText.label()),
                  ),
                ),
                IconButton(
                  onPressed: _weekOffset < 4
                      ? () => setState(() {
                            _weekOffset++;
                            _preloadWeek();
                          })
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              children: [
                for (var d = 0; d < 7; d++) _dayRow(d, week, state, s),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    week.isEmpty ? null : () => _exportWeek(state, s),
                icon: const Icon(Icons.playlist_add,
                    size: 16, color: MorphColors.teal),
                label: Text(s('exportWeekToList'),
                    style: MorphText.label(color: MorphColors.teal)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: MorphColors.teal),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sum of one eaten serving per planned meal that day — leftovers count,
  /// they are dinner too.
  int _dayCalories(int dayIndex, Map<String, String> week, AppState state) {
    var total = 0;
    for (final slot in mealSlots) {
      final entry = week['${weekDays[dayIndex]}.$slot'];
      if (entry == null) continue;
      final recipe = state.corpus.loadedRecipeById(plannedRecipeId(entry));
      total += recipe?.caloriesPerServing ?? 0;
    }
    return total;
  }

  Widget _dayRow(
      int dayIndex, Map<String, String> week, AppState state, S s) {
    final date = _weekDate.add(Duration(days: dayIndex));
    final calories = _dayCalories(dayIndex, week, state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: Row(
            children: [
              Text(
                '${s(weekDays[dayIndex])} ${date.day}.${date.month}.'
                    .toLowerCase(),
                style: MorphText.label(),
              ),
              const Spacer(),
              if (calories > 0)
                Text('~$calories kcal',
                    style: MorphText.label(
                        size: 9, color: MorphColors.inkSoft)),
            ],
          ),
        ),
        Row(
          children: [
            for (final slot in mealSlots) ...[
              Expanded(child: _slotCell(dayIndex, slot, week, state, s)),
              if (slot != mealSlots.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  /// Day index (0 = Monday) on which a recipe is cooked in this week, i.e.
  /// its earliest non-leftover slot. Null when it is not cooked this week.
  int? _cookDayOf(String recipeId, Map<String, String> week) {
    for (var d = 0; d < 7; d++) {
      for (final slot in mealSlots) {
        final entry = week['${weekDays[d]}.$slot'];
        if (entry == null || isLeftoverEntry(entry)) continue;
        if (entry == recipeId) return d;
      }
    }
    return null;
  }

  /// A leftover kept longer than the recipe's fridge life. Only checked
  /// against a cook day in the same week — cross-week prep is on you.
  bool _leftoverExpired(int dayIndex, String recipeId,
      Map<String, String> week, AppState state) {
    final cookDay = _cookDayOf(recipeId, week);
    if (cookDay == null || cookDay > dayIndex) return false;
    final recipe = state.corpus.loadedRecipeById(recipeId);
    if (recipe == null) return false;
    return dayIndex - cookDay > recipe.fridgeLifeDays;
  }

  Widget _slotCell(int dayIndex, String slot, Map<String, String> week,
      AppState state, S s) {
    final slotKey = '${weekDays[dayIndex]}.$slot';
    final entry = week[slotKey];
    final recipeId = entry == null ? null : plannedRecipeId(entry);
    final isLeftover = entry != null && isLeftoverEntry(entry);
    final recipe =
        recipeId == null ? null : state.corpus.loadedRecipeById(recipeId);
    final expired = isLeftover &&
        recipeId != null &&
        _leftoverExpired(dayIndex, recipeId, week, state);

    final cell = DragTarget<String>(
      onAcceptWithDetails: (details) =>
          state.moveMeal(_weekKey, details.data, slotKey),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return GestureDetector(
          onTap: () => _assignSlot(slotKey, state, s),
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: entry == null
                  ? Colors.transparent
                  : isLeftover
                      ? MorphColors.butter.withValues(alpha: 0.22)
                      : MorphColors.card,
              border: Border.all(
                color: highlighted
                    ? MorphColors.terracotta
                    : expired
                        ? MorphColors.coral
                        : MorphColors.line,
                width: highlighted || expired ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(s(slot), style: MorphText.label(size: 8)),
                    const Spacer(),
                    if (isLeftover)
                      Text(
                        expired
                            ? '⚠ ${s('pastFridgeLife')}'
                            : '↩ ${s('leftovers')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MorphText.label(
                            size: 7,
                            color: expired
                                ? MorphColors.coral
                                : MorphColors.teal),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  entry == null
                      ? s('planEmptySlot')
                      : recipe == null
                          ? '…'
                          : recipe.title.of(state.lang).toLowerCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: entry == null
                      ? MorphText.hand.copyWith(
                          fontSize: 14, color: MorphColors.inkFaint)
                      : MorphText.mono.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (entry == null) return cell;
    // Drag carries the source slot key; drop target moves the assignment.
    return LongPressDraggable<String>(
      data: slotKey,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          color: MorphColors.ink,
          child: Text(
            recipe?.title.of(state.lang).toLowerCase() ?? '',
            style: MorphText.mono
                .copyWith(fontSize: 11, color: MorphColors.cream),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: cell),
      child: cell,
    );
  }

  /// Recipes cooked this week (non-leftover entries) — the sources a
  /// manual leftover slot can draw from.
  List<Recipe> _leftoverSources(AppState state) {
    final week = state.mealPlan[_weekKey] ?? const <String, String>{};
    final seen = <String>{};
    final sources = <Recipe>[];
    for (final entry in week.values) {
      if (isLeftoverEntry(entry) || !seen.add(entry)) continue;
      final recipe = state.corpus.loadedRecipeById(entry);
      if (recipe != null) sources.add(recipe);
    }
    return sources;
  }

  Future<void> _assignSlot(String slotKey, AppState state, S s) async {
    final existing = state.mealPlan[_weekKey]?[slotKey];
    final hasLeftoverSources = _leftoverSources(state).isNotEmpty;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: MorphColors.paper,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(s('pickRecipe'), style: MorphText.label()),
            ListTile(
              leading: const Icon(Icons.bookmark_border,
                  color: MorphColors.terracotta),
              title: Text(s('fromCookbook'),
                  style: MorphText.mono.copyWith(fontSize: 13)),
              onTap: () => Navigator.pop(context, 'cookbook'),
            ),
            ListTile(
              leading: const Icon(Icons.search, color: MorphColors.teal),
              title: Text(s('fromSearch'),
                  style: MorphText.mono.copyWith(fontSize: 13)),
              onTap: () => Navigator.pop(context, 'search'),
            ),
            if (hasLeftoverSources)
              ListTile(
                leading: const Icon(Icons.replay_circle_filled_outlined,
                    color: MorphColors.butter),
                title: Text(s('fromLeftovers'),
                    style: MorphText.mono.copyWith(fontSize: 13)),
                onTap: () => Navigator.pop(context, 'leftovers'),
              ),
            if (existing != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: MorphColors.coral),
                title: Text(s('removeFromSlot'),
                    style: MorphText.mono.copyWith(fontSize: 13)),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'remove') {
      await state.clearMeal(_weekKey, slotKey);
      return;
    }

    if (action == 'leftovers') {
      final source = await _pickLeftoverSource(state, s);
      if (source != null) {
        await state.assignLeftover(_weekKey, slotKey, source.id);
      }
      return;
    }

    Recipe? picked;
    if (action == 'cookbook') {
      picked = await _pickFromCookbook(state, s);
    } else {
      picked = await Navigator.of(context).push<Recipe>(MaterialPageRoute(
          builder: (_) => Scaffold(
                appBar: AppBar(
                    title: Text(s('pickRecipe'),
                        style: MorphText.display.copyWith(fontSize: 20))),
                body: const PaperBackground(
                    child: SearchScreen(pickerMode: true)),
              )));
    }
    if (picked != null) {
      await state.assignMeal(_weekKey, slotKey, picked.id);
      await _maybePlanLeftovers(picked, slotKey, state, s);
    }
  }

  Future<Recipe?> _pickLeftoverSource(AppState state, S s) async {
    final sources = _leftoverSources(state);
    if (!mounted) return null;
    return showModalBottomSheet<Recipe>(
      context: context,
      backgroundColor: MorphColors.paper,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(s('fromLeftovers'), style: MorphText.label()),
            for (final recipe in sources)
              ListTile(
                leading: const Icon(Icons.replay_circle_filled_outlined,
                    color: MorphColors.butter),
                title: Text(recipe.title.of(state.lang).toLowerCase(),
                    style: MorphText.mono.copyWith(fontSize: 13)),
                subtitle: Text(
                  '${recipe.fridgeLifeDays} '
                  '${s(recipe.fridgeLifeDays == 1 ? 'fridgeDay' : 'fridgeDays')}'
                      .toLowerCase(),
                  style: MorphText.label(size: 9),
                ),
                onTap: () => Navigator.pop(context, recipe),
              ),
          ],
        ),
      ),
    );
  }

  /// Free lunch/dinner slots after [fromSlotKey], chronological, capped at
  /// the recipe's fridge life and the end of the week.
  List<String> _leftoverTargetSlots(
      String fromSlotKey, Recipe recipe, AppState state) {
    final week = state.mealPlan[_weekKey] ?? const <String, String>{};
    final cookDay = weekDays.indexOf(fromSlotKey.split('.').first);
    final cookSlot = mealSlots.indexOf(fromSlotKey.split('.').last);
    if (cookDay < 0) return const [];

    final lastDay = (cookDay + recipe.fridgeLifeDays).clamp(0, 6);
    final targets = <String>[];
    for (var d = cookDay; d <= lastDay; d++) {
      for (final slot in ['lunch', 'dinner']) {
        if (d == cookDay && mealSlots.indexOf(slot) <= cookSlot) continue;
        final key = '${weekDays[d]}.$slot';
        if (!week.containsKey(key)) targets.add(key);
      }
    }
    return targets;
  }

  /// After planning a multi-serving cook, offer to spread the remaining
  /// portions over the following free slots.
  Future<void> _maybePlanLeftovers(
      Recipe recipe, String slotKey, AppState state, S s) async {
    if (recipe.servings < 2) return;
    final targets = _leftoverTargetSlots(slotKey, recipe, state);
    if (targets.isEmpty || !mounted) return;
    final maxMeals =
        (recipe.servings - 1).clamp(1, targets.length).clamp(1, 6);

    final count = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: MorphColors.paper,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s('planLeftovers'),
                  style: MorphText.display.copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              Text(s('planLeftoversBody'),
                  style: MorphText.hand.copyWith(
                      fontSize: 17, color: MorphColors.inkSoft)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var n = 1; n <= maxMeals; n++)
                    MonoChip(
                      label: '$n × ${s('leftovers')}',
                      onTap: () => Navigator.pop(context, n),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(s('notNow'), style: MorphText.label()),
              ),
            ],
          ),
        ),
      ),
    );
    if (count == null || !mounted) return;

    for (var i = 0; i < count && i < targets.length; i++) {
      await state.assignLeftover(_weekKey, targets[i], recipe.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count ${s('leftoversPlanned')}')));
  }

  Future<Recipe?> _pickFromCookbook(AppState state, S s) async {
    final recipes = <Recipe>[];
    for (final saved in state.saved.reversed) {
      final r = await state.corpus.recipeById(saved.recipeId);
      if (r != null) recipes.add(r);
    }
    if (!mounted) return null;
    return showModalBottomSheet<Recipe>(
      context: context,
      backgroundColor: MorphColors.paper,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, controller) => recipes.isEmpty
            ? Center(
                child: Text(s('cookbookEmpty'),
                    textAlign: TextAlign.center,
                    style: MorphText.hand.copyWith(
                        fontSize: 19, color: MorphColors.inkSoft)))
            : ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(20),
                itemCount: recipes.length,
                itemBuilder: (context, i) => RecipeRow(
                  recipe: recipes[i],
                  index: i,
                  onTap: () => Navigator.pop(context, recipes[i]),
                ),
              ),
      ),
    );
  }

  Future<void> _exportWeek(AppState state, S s) async {
    final week = state.mealPlan[_weekKey] ?? const <String, String>{};
    final recipes = <(Recipe, double)>[];
    for (final entry in week.values) {
      // Leftover slots eat what a cook slot already bought — skip them.
      if (isLeftoverEntry(entry)) continue;
      final recipe = await state.corpus.recipeById(entry);
      if (recipe != null) recipes.add((recipe, 1.0));
    }
    if (recipes.isEmpty) return;
    await state.addToShoppingList(recipes);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(s('weekExported'))));
  }
}
