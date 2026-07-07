import 'package:flutter/foundation.dart';

typedef LText = Map<String, String>;

String tr(LText text, String lang) {
  return text[lang] ?? text['en'] ?? text.values.firstOrNull ?? '';
}

LText L(String en, [String? de]) => {'en': en, if (de != null) 'de': de};

@immutable
class Ingredient {
  final String id;
  final LText name;
  final double quantity;
  final String unit;
  final String aisle;

  const Ingredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.aisle,
  });

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: j['id'] as String,
        name: Map<String, String>.from(j['name'] as Map),
        quantity: (j['quantity'] as num).toDouble(),
        unit: j['unit'] as String,
        aisle: j['aisle'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': Map<String, String>.from(name),
        'quantity': quantity,
        'unit': unit,
        'aisle': aisle,
      };
}

@immutable
class Step {
  final int n;
  final LText text;
  final int timerSeconds;

  const Step({required this.n, required this.text, required this.timerSeconds});

  factory Step.fromJson(Map<String, dynamic> j) => Step(
        n: j['n'] as int,
        text: Map<String, String>.from(j['text'] as Map),
        timerSeconds: (j['timer_seconds'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class Recipe {
  final String id;
  final String dishId;
  final LText title;
  final String diet;
  final String effort;
  final String calorieLevel;
  final List<String> extraTags;
  final List<String> contains;
  final Map<String, dynamic> attributes;
  final int timeMinutes;
  final int caloriesPerServing;
  final Map<String, int> macros;
  final int servings;
  final List<Ingredient> ingredients;
  final List<Step> steps;
  final List<String> tags;
  final List<String> cuisineTags;
  final String frequencyTier;

  const Recipe({
    required this.id,
    required this.dishId,
    required this.title,
    required this.diet,
    required this.effort,
    required this.calorieLevel,
    required this.extraTags,
    required this.contains,
    required this.attributes,
    required this.timeMinutes,
    required this.caloriesPerServing,
    required this.macros,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.tags,
    required this.cuisineTags,
    required this.frequencyTier,
  });

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'] as String,
        dishId: j['dish_id'] as String,
        title: Map<String, String>.from(j['title'] as Map),
        diet: j['diet'] as String,
        effort: j['effort'] as String,
        calorieLevel: j['calorie_level'] as String,
        extraTags: List<String>.from(j['extra_tags'] as List? ?? const []),
        contains: List<String>.from(j['contains'] as List? ?? const []),
        attributes: Map<String, dynamic>.from(j['attributes'] as Map? ?? const {}),
        timeMinutes: (j['time_minutes'] as num).toInt(),
        caloriesPerServing: (j['calories_per_serving'] as num).toInt(),
        macros: (j['macros'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        servings: (j['servings'] as num?)?.toInt() ?? 4,
        ingredients: (j['ingredients'] as List).map((e) => Ingredient.fromJson(e as Map<String, dynamic>)).toList(),
        steps: (j['steps'] as List).map((e) => Step.fromJson(e as Map<String, dynamic>)).toList(),
        tags: List<String>.from(j['tags'] as List? ?? const []),
        cuisineTags: List<String>.from(j['cuisine_tags'] as List? ?? const []),
        frequencyTier: j['frequency_tier'] as String? ?? 'core',
      );

  List<String> get techniques =>
      (attributes['technique'] as List?)?.map((e) => e.toString()).toList() ?? const [];
  List<String> get mealTypes =>
      (attributes['meal_type'] as List?)?.map((e) => e.toString()).toList() ?? const [];
  String get timeBucket => attributes['time_bucket'] as String? ?? '';
  String get calorieBucket => attributes['calorie_bucket'] as String? ?? '';
}

@immutable
class Dish {
  final String id;
  final LText canonicalName;
  final LText heroText;
  final LText capCaption;
  final String stripeColor;
  final String frequencyTier;
  final String partitionId;
  final List<String> secondaryPartitions;
  final List<String> cuisineTags;
  final List<String> variantRecipeIds;

  const Dish({
    required this.id,
    required this.canonicalName,
    required this.heroText,
    required this.capCaption,
    required this.stripeColor,
    required this.frequencyTier,
    required this.partitionId,
    required this.secondaryPartitions,
    required this.cuisineTags,
    required this.variantRecipeIds,
  });

  factory Dish.fromJson(Map<String, dynamic> j) => Dish(
        id: j['id'] as String,
        canonicalName: Map<String, String>.from(j['canonical_name'] as Map),
        heroText: Map<String, String>.from(j['hero_text'] as Map),
        capCaption: Map<String, String>.from(j['cap_caption'] as Map),
        stripeColor: j['stripe_color'] as String,
        frequencyTier: j['frequency_tier'] as String? ?? 'core',
        partitionId: j['partition_id'] as String? ?? 'core-recipes',
        secondaryPartitions: List<String>.from(j['secondary_partitions'] as List? ?? const []),
        cuisineTags: List<String>.from(j['cuisine_tags'] as List? ?? const []),
        variantRecipeIds: List<String>.from(j['variant_recipe_ids'] as List? ?? const []),
      );
}

@immutable
class Ontology {
  final List<String> containsFlags;
  final Map<String, List<String>> compoundFlags;
  final Map<String, List<String>> attributes;
  final List<String> diets;
  final List<String> sparseExtras;

  const Ontology({
    required this.containsFlags,
    required this.compoundFlags,
    required this.attributes,
    required this.diets,
    required this.sparseExtras,
  });

  factory Ontology.fromJson(Map<String, dynamic> j) => Ontology(
        containsFlags: List<String>.from(j['contains_flags'] as List),
        compoundFlags: (j['compound_flags'] as Map).map(
          (k, v) => MapEntry(k as String, List<String>.from(v as List)),
        ),
        attributes: (j['attributes'] as Map).map(
          (k, v) => MapEntry(k as String, List<String>.from(v as List)),
        ),
        diets: List<String>.from(j['diets'] as List? ?? const ['classic', 'vegetarian', 'vegan']),
        sparseExtras: List<String>.from(j['sparse_extras'] as List? ?? const ['gluten-free', 'low-fodmap']),
      );

  /// Expand a set of compound flags + simple avoid flags into the full set
  /// of base contains-flags to avoid.
  Set<String> expandAvoidFlags(Set<String> input) {
    final out = <String>{};
    for (final f in input) {
      final expanded = compoundFlags[f];
      if (expanded != null) {
        out.addAll(expanded);
      } else {
        out.add(f);
      }
    }
    return out;
  }
}

@immutable
class IngredientNode {
  final String id;
  final LText name;
  final Map<String, IngredientNode> children;

  const IngredientNode({required this.id, required this.name, required this.children});

  factory IngredientNode.fromJson(String id, Map<String, dynamic> j) {
    final nameMap = Map<String, String>.from(j['name'] as Map);
    final childrenRaw = j['children'] as Map? ?? {};
    final children = childrenRaw.map<String, IngredientNode>(
      (k, v) => MapEntry(k as String, IngredientNode.fromJson(k, v as Map<String, dynamic>)),
    );
    return IngredientNode(id: id, name: nameMap, children: children);
  }

  /// Collect all descendant ids (including self).
  Iterable<String> allDescendants() sync* {
    yield id;
    for (final child in children.values) {
      yield* child.allDescendants();
    }
  }
}

@immutable
class IngredientTree {
  final Map<String, IngredientNode> roots;

  const IngredientTree(this.roots);

  factory IngredientTree.fromJson(Map<String, dynamic> j) {
    final tree = j['tree'] as Map;
    return IngredientTree(
      tree.map<String, IngredientNode>(
        (k, v) => MapEntry(k as String, IngredientNode.fromJson(k, v as Map<String, dynamic>)),
      ),
    );
  }

  /// Flatten into a list of (id, displayName) for typeahead, depth-first.
  List<({String id, LText name, int depth})> flatten() {
    final out = <({String id, LText name, int depth})>[];
    void walk(IngredientNode node, int depth) {
      out.add((id: node.id, name: node.name, depth: depth));
      for (final child in node.children.values) {
        walk(child, depth + 1);
      }
    }
    for (final root in roots.values) {
      walk(root, 0);
    }
    return out;
  }

  /// Find a node by id.
  IngredientNode? find(String id) {
    IngredientNode? search(Iterable<IngredientNode> nodes) {
      for (final n in nodes) {
        if (n.id == id) return n;
        final found = search(n.children.values);
        if (found != null) return found;
      }
      return null;
    }
    return search(roots.values);
  }

  /// Expand an ingredient id to itself + all descendant ids (for avoidance propagation).
  Set<String> expand(String id) {
    final node = find(id);
    if (node == null) return {id};
    return node.allDescendants().toSet();
  }
}

@immutable
class FaqEntry {
  final String id;
  final String category;
  final LText question;
  final LText answer;

  const FaqEntry({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  factory FaqEntry.fromJson(Map<String, dynamic> j) => FaqEntry(
        id: j['id'] as String,
        category: j['category'] as String,
        question: Map<String, String>.from(j['question'] as Map),
        answer: Map<String, String>.from(j['answer'] as Map),
      );
}

@immutable
class IngredientGuideEntry {
  final String id;
  final LText name;
  final LText description;
  final LText usage;
  final LText storage;
  final LText whereToFind;

  const IngredientGuideEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.usage,
    required this.storage,
    required this.whereToFind,
  });

  factory IngredientGuideEntry.fromJson(Map<String, dynamic> j) => IngredientGuideEntry(
        id: j['id'] as String,
        name: Map<String, String>.from(j['name'] as Map),
        description: Map<String, String>.from(j['description'] as Map),
        usage: Map<String, String>.from(j['usage'] as Map),
        storage: Map<String, String>.from(j['storage'] as Map),
        whereToFind: Map<String, String>.from(j['where_to_find'] as Map),
      );
}
