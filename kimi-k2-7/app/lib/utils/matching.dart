import '../models/ingredient.dart';
import '../models/ontology.dart';
import '../models/profile.dart';
import '../models/recipe.dart';

class RecipeMatcher {
  final Ontology? ontology;
  final AvoidanceTree? ingredientTree;

  RecipeMatcher({this.ontology, this.ingredientTree});

  bool visible(Recipe recipe, Profile profile) {
    final expandedAvoid = ontology?.expandFlags(profile.avoidFlags) ?? profile.avoidFlags.toList();
    if (_intersects(recipe.contains, expandedAvoid)) return false;

    final avoidedIds = profile.avoidIngredients
        .expand((id) => ingredientTree?.descendantsOf(id) ?? {id})
        .toSet();
    final recipeIds = recipe.ingredients.map((i) => i.ingredientId).toSet();
    if (avoidedIds.intersection(recipeIds).isNotEmpty) return false;

    for (final attr in profile.requiredAttributes) {
      if (!recipe.attributes.contains(attr) && !recipe.contains.contains(attr)) {
        return false;
      }
    }

    if (recipe.timeMinutes > profile.maxTimeMinutes) return false;

    final tolerance = 100;
    final calorieDiff = (recipe.caloriesPerServing - profile.calorieTarget).abs();
    if (calorieDiff > tolerance) return false;

    return true;
  }

  bool _intersects(List<String> list, List<String> flags) {
    final set = list.toSet();
    for (final f in flags) {
      if (set.contains(f)) return true;
    }
    return false;
  }

  int scoreVariant(Recipe recipe, Profile profile) {
    int score = 0;
    for (final attr in profile.requiredAttributes) {
      if (recipe.attributes.contains(attr)) score += 100;
    }
    if (recipe.effort == profile.preferredEffort) score += 80;
    score += 100 - (recipe.timeMinutes - profile.maxTimeMinutes).abs();
    score += 100 - (recipe.caloriesPerServing - profile.calorieTarget).abs();
    return score;
  }

  Recipe? bestVariant(List<Recipe> variants, Profile profile) {
    final visibleVariants = variants.where((r) => visible(r, profile)).toList();
    if (visibleVariants.isEmpty) return null;
    visibleVariants.sort((a, b) => scoreVariant(b, profile).compareTo(scoreVariant(a, profile)));
    return visibleVariants.first;
  }

  int timeAwareBonus(Recipe recipe, DateTime now) {
    int bonus = 0;
    final hour = now.hour;
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
    final isBreakfast = recipe.attributes.contains('breakfast');
    final isDinner = recipe.attributes.contains('dinner');
    if (hour >= 5 && hour < 11 && isBreakfast) bonus += 200;
    if (hour >= 17 && hour < 21 && isDinner) bonus += 90;
    if (isWeekend && (recipe.effort == 'medium' || recipe.effort == 'hard')) bonus += 90;
    return bonus;
  }

  int stalenessBonus(Recipe recipe, Map<String, DateTime> lastCooked) {
    final last = lastCooked[recipe.id];
    if (last == null) return 0;
    final days = DateTime.now().difference(last).inDays;
    if (days >= 30) return 50;
    return 0;
  }
}
