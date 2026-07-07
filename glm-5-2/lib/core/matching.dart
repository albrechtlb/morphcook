import '../models/models.dart';
import '../models/profile.dart';

/// Result of matching a recipe against a profile.
class MatchResult {
  final bool visible;
  final int score;
  final Set<String> conflictFlags;
  final Set<String> conflictIngredients;

  const MatchResult({
    required this.visible,
    required this.score,
    required this.conflictFlags,
    required this.conflictIngredients,
  });

  static const MatchResult hidden = MatchResult(
    visible: false,
    score: -1,
    conflictFlags: {},
    conflictIngredients: {},
  );
}

/// Pure matching algorithm. See SPEC.md.
///
/// visible(recipe, profile) :=
///   recipe.contains ∩ profile.avoid_flags = ∅
///   AND profile.avoid_ingredients ∩ recipe.ingredient_ids = ∅
///   AND profile.required_attributes ⊆ recipe.attributes
///   AND recipe.time_minutes ≤ profile.max_time_minutes
///   AND |recipe.calories_per_serving - profile.calorie_target| ≤ tolerance
MatchResult matchRecipe(
  Recipe recipe,
  Profile profile,
  Ontology ontology, {
  bool ignoreTimeFilter = false,
  bool ignoreCalorieFilter = false,
}) {
  final expandedAvoid = ontology.expandAvoidFlags(profile.avoidFlags);
  final ingredientIds = recipe.ingredients.map((e) => e.id).toSet();

  // contains ∩ avoid_flags
  final conflictFlags = recipe.contains.toSet().intersection(expandedAvoid);

  // avoid_ingredients ∩ ingredient_ids (with tree propagation)
  final expandedIngredientAvoid = <String>{};
  // Note: ingredient expansion handled by caller via IngredientTree; here
  // we use pre-expanded ids as stored in avoidIngredients.
  expandedIngredientAvoid.addAll(profile.avoidIngredients);
  final conflictIngredients = ingredientIds.intersection(expandedIngredientAvoid);

  // required_attributes ⊆ recipe.attributes (technique/meal_type are list
  // attributes; treat single-value attributes only as required)
  final requiredOk = profile.requiredAttributes.every((req) {
    final v = recipe.attributes[req];
    if (v is String) return v == req || recipe.techniques.contains(req) || recipe.mealTypes.contains(req);
    if (v is List) return v.contains(req);
    return recipe.techniques.contains(req) || recipe.mealTypes.contains(req);
  });

  final timeOk = ignoreTimeFilter || !profile.timeHardFilter || recipe.timeMinutes <= profile.maxTimeMinutes;
  final calOk = ignoreCalorieFilter ||
      !profile.calorieHardFilter ||
      (recipe.caloriesPerServing - profile.calorieTarget).abs() <= profile.calorieTolerance;

  final visible = conflictFlags.isEmpty && conflictIngredients.isEmpty && requiredOk && timeOk && calOk;

  // scoring
  var score = 0;
  // effort match
  if (recipe.effort == profile.preferredEffort) score += 50;
  // time closeness
  final timeDiff = (recipe.timeMinutes - profile.maxTimeMinutes).abs();
  score += (60 - timeDiff).clamp(0, 60);
  // calorie closeness
  final calDiff = (recipe.caloriesPerServing - profile.calorieTarget).abs();
  score += (profile.calorieTolerance - calDiff).clamp(0, profile.calorieTolerance);

  return MatchResult(
    visible: visible,
    score: score,
    conflictFlags: conflictFlags,
    conflictIngredients: conflictIngredients,
  );
}

/// Time-of-day bonus. See SPEC.md.
int timeOfDayBonus(Recipe recipe, DateTime now) {
  var bonus = 0;
  final hour = now.hour;
  final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  if (hour >= 5 && hour < 11 && recipe.mealTypes.contains('breakfast')) bonus += 200;
  if (hour >= 17 && hour < 21 && recipe.mealTypes.contains('dinner')) bonus += 90;
  if (isWeekend && (recipe.effort == 'medium' || recipe.effort == 'hard')) bonus += 90;
  return bonus;
}

/// Staleness bonus. See SPEC.md.
///
/// [lastCookedAt] is the last time this recipe id was cooked (or null if never).
int stalenessBonus(DateTime? lastCookedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  if (lastCookedAt == null) return 0;
  final days = reference.difference(lastCookedAt).inDays;
  if (days >= 30) return 50;
  return 0;
}

/// Pick the best recipe out of a list, considering profile + time/staleness.
Recipe? pickBestVariant(
  List<Recipe> variants,
  Profile profile,
  Ontology ontology, {
  DateTime? now,
  DateTime? Function(String recipeId)? lastCookedLookup,
}) {
  final reference = now ?? DateTime.now();
  final candidates = variants
      .map((r) {
        final m = matchRecipe(r, profile, ontology);
        if (!m.visible) return null;
        final score = m.score + timeOfDayBonus(r, reference) + stalenessBonus(lastCookedLookup?.call(r.id), now: reference);
        return (r: r, score: score);
      })
      .whereType<({Recipe r, int score})>()
      .toList();
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.score.compareTo(a.score));
  return candidates.first.r;
}

/// Filter visible dishes: return all dishes that have at least one
/// matching recipe variant.
List<({Dish dish, Recipe? bestVariant, List<Recipe> visibleVariants})> visibleDishes(
  List<Dish> dishes,
  Map<String, Recipe> recipeIndex,
  Profile profile,
  Ontology ontology, {
  DateTime? now,
  DateTime? Function(String recipeId)? lastCookedLookup,
}) {
  final out = <({Dish dish, Recipe? bestVariant, List<Recipe> visibleVariants})>[];
  for (final d in dishes) {
    final variants = d.variantRecipeIds.map((id) => recipeIndex[id]).whereType<Recipe>().toList();
    final visible =
        variants.where((r) => matchRecipe(r, profile, ontology).visible).toList();
    if (visible.isEmpty) continue;
    final best = pickBestVariant(variants, profile, ontology, now: now, lastCookedLookup: lastCookedLookup);
    out.add((dish: d, bestVariant: best, visibleVariants: visible));
  }
  return out;
}
