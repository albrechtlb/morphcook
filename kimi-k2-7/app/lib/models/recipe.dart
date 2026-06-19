import 'localized.dart';

class RecipeIngredient {
  final String ingredientId;
  final LocalizedString name;
  final double? quantity;
  final String? unit;
  final bool optional;
  final LocalizedString? notes;

  RecipeIngredient({
    required this.ingredientId,
    required this.name,
    this.quantity,
    this.unit,
    this.optional = false,
    this.notes,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      ingredientId: map['ingredient_id'] as String? ?? '',
      name: LocalizedString.fromMap((map['name'] as Map?)?.cast<String, dynamic>() ?? {}),
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      optional: map['optional'] as bool? ?? false,
      notes: map['notes'] == null
          ? null
          : LocalizedString.fromMap((map['notes'] as Map).cast<String, dynamic>()),
    );
  }

  Map<String, dynamic> toMap() => {
        'ingredient_id': ingredientId,
        'name': name.toMap(),
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        'optional': optional,
        if (notes != null) 'notes': notes!.toMap(),
      };
}

class RecipeStep {
  final LocalizedString text;
  final int? timerSeconds;

  RecipeStep({required this.text, this.timerSeconds});

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      text: LocalizedString.fromMap(map['text']),
      timerSeconds: map['timer_seconds'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text.toMap(),
        if (timerSeconds != null) 'timer_seconds': timerSeconds,
      };
}

class Recipe {
  final String id;
  final String dishId;
  final LocalizedString title;
  final LocalizedString subtitle;
  final String diet;
  final String effort;
  final int caloriesPerServing;
  final int timeMinutes;
  final int servings;
  final List<String> contains;
  final List<String> attributes;
  final List<String> cuisineTags;
  final String partitionId;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> method;
  final List<String> tags;

  Recipe({
    required this.id,
    required this.dishId,
    required this.title,
    required this.subtitle,
    required this.diet,
    required this.effort,
    required this.caloriesPerServing,
    required this.timeMinutes,
    required this.servings,
    required this.contains,
    required this.attributes,
    required this.cuisineTags,
    required this.partitionId,
    required this.ingredients,
    required this.method,
    required this.tags,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as String? ?? '',
      dishId: map['dish_id'] as String? ?? '',
      title: LocalizedString.fromMap(map['title']),
      subtitle: LocalizedString.fromMap(map['subtitle']),
      diet: map['diet'] as String? ?? '',
      effort: map['effort'] as String? ?? 'medium',
      caloriesPerServing: (map['calories_per_serving'] as num?)?.toInt() ?? 0,
      timeMinutes: (map['time_minutes'] as num?)?.toInt() ?? 0,
      servings: (map['servings'] as num?)?.toInt() ?? 1,
      contains: map.stringList('contains'),
      attributes: map.stringList('attributes'),
      cuisineTags: map.stringList('cuisine_tags'),
      partitionId: map['partition_id'] as String? ?? 'core',
      ingredients: (map['ingredients'] as List? ?? [])
          .whereType<Map>()
          .map((e) => RecipeIngredient.fromMap(e.cast<String, dynamic>()))
          .toList(),
      method: (map['method'] as List? ?? [])
          .whereType<Map>()
          .map((e) => RecipeStep.fromMap(e.cast<String, dynamic>()))
          .toList(),
      tags: map.stringList('tags'),
    );
  }

  String localizedTitle(String lang) => title.text(lang);

  String displayTitle(String lang) {
    final t = title.text(lang);
    final s = subtitle.text(lang);
    if (s.trim().isEmpty) return t;
    return '$t — $s';
  }
}
