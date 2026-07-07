import 'profile.dart';
import 'recipe.dart';

class Ontology {
  final String version;
  final List<String> containsFlags;
  final Map<String, List<String>> compoundAvoidFlags;
  final Map<String, List<String>> attributes;
  final List<String> dietDimensions;
  final List<String> calorieLevels;

  Ontology({
    required this.version,
    required this.containsFlags,
    required this.compoundAvoidFlags,
    required this.attributes,
    required this.dietDimensions,
    required this.calorieLevels,
  });

  factory Ontology.fromJson(Map<String, dynamic> json) {
    return Ontology(
      version: json['version'],
      containsFlags: List<String>.from(json['contains_flags']),
      compoundAvoidFlags:
          Map<String, List<String>>.from(json['compound_avoid_flags'].map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          )),
      attributes: Map<String, List<String>>.from(json['attributes'].map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      )),
      dietDimensions: List<String>.from(json['diet_dimensions']),
      calorieLevels: List<String>.from(json['calorie_levels']),
    );
  }

  List<String> expandCompoundFlag(String flag) {
    return compoundAvoidFlags[flag] ?? [flag];
  }

  bool recipeMatchesProfile(Recipe recipe, Profile profile) {
    final tolerance = (profile.calorieTarget * 0.2).round();

    final recipeFlags = recipe.contains.toSet();
    final profileAvoidExpanded = <String>{};
    for (final flag in profile.avoidFlags) {
      profileAvoidExpanded.addAll(expandCompoundFlag(flag));
    }

    if (recipeFlags.intersection(profileAvoidExpanded).isNotEmpty) {
      return false;
    }

    if (profile.avoidIngredients.intersection(recipe.ingredients
            .map((i) => i.id)
            .toSet())
        .isNotEmpty) {
      return false;
    }

    if (!profile.requiredAttributes
        .every((attr) => recipe.attributes.contains(attr))) {
      return false;
    }

    if (recipe.timeMinutes > profile.maxTimeMinutes) {
      return false;
    }

    if ((recipe.caloriesPerServing - profile.calorieTarget).abs() > tolerance) {
      return false;
    }

    return true;
  }
}
