class Ingredient {
  final String id;
  final Map<String, String> name;
  final double amount;
  final String unit;

  Ingredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: Map<String, String>.from(json['name']),
      amount: json['amount'].toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
    };
  }
}

class Step {
  final int order;
  final Map<String, String> text;

  Step({
    required this.order,
    required this.text,
  });

  factory Step.fromJson(Map<String, dynamic> json) {
    return Step(
      order: json['order'],
      text: Map<String, String>.from(json['text']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'text': text,
    };
  }
}

class Recipe {
  final String id;
  final String dishId;
  final Map<String, String> variantLabel;
  final String diet;
  final String effort;
  final int timeMinutes;
  final int caloriesPerServing;
  final List<String> contains;
  final List<String> attributes;
  final int servings;
  final List<Ingredient> ingredients;
  final List<Step> steps;
  final List<String> tags;

  Recipe({
    required this.id,
    required this.dishId,
    required this.variantLabel,
    required this.diet,
    required this.effort,
    required this.timeMinutes,
    required this.caloriesPerServing,
    required this.contains,
    required this.attributes,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.tags,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      dishId: json['dish_id'],
      variantLabel: Map<String, String>.from(json['variant_label']),
      diet: json['diet'],
      effort: json['effort'],
      timeMinutes: json['time_minutes'],
      caloriesPerServing: json['calories_per_serving'],
      contains: List<String>.from(json['contains']),
      attributes: List<String>.from(json['attributes']),
      servings: json['servings'],
      ingredients: (json['ingredients'] as List)
          .map((i) => Ingredient.fromJson(i))
          .toList(),
      steps: (json['steps'] as List).map((s) => Step.fromJson(s)).toList(),
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dish_id': dishId,
      'variant_label': variantLabel,
      'diet': diet,
      'effort': effort,
      'time_minutes': timeMinutes,
      'calories_per_serving': caloriesPerServing,
      'contains': contains,
      'attributes': attributes,
      'servings': servings,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'tags': tags,
    };
  }

  String localizedVariantLabel(String lang) {
    return variantLabel[lang] ?? variantLabel['en'] ?? '';
  }
}
