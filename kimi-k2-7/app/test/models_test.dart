import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/models/ingredient.dart';
import 'package:morphcook/models/localized.dart';
import 'package:morphcook/models/ontology.dart';
import 'package:morphcook/models/profile.dart';
import 'package:morphcook/models/recipe.dart';
import 'package:morphcook/utils/matching.dart';

Recipe _recipe({
  List<String> contains = const [],
  List<String> ingredientIds = const [],
  int calories = 500,
  int time = 30,
  List<String> attributes = const [],
}) {
  return Recipe(
    id: 'r1',
    dishId: 'dish1',
    title: const LocalizedString({'en': 'Test'}),
    subtitle: const LocalizedString({'en': 'Subtitle'}),
    diet: 'classic',
    effort: 'medium',
    caloriesPerServing: calories,
    timeMinutes: time,
    servings: 2,
    contains: contains,
    attributes: attributes,
    cuisineTags: [],
    partitionId: 'core',
    ingredients: ingredientIds
        .map((id) => RecipeIngredient(
              ingredientId: id,
              name: LocalizedString({'en': id}),
            ))
        .toList(),
    method: [],
    tags: [],
  );
}

Ontology _ontology() {
  return Ontology(
    containsFlags: {
      'dairy': const LocalizedString({'en': 'dairy'}),
      'nuts': const LocalizedString({'en': 'nuts'}),
    },
    compoundFlags: {
      'vegan': ['dairy'],
    },
    attributes: {
      'effort': {'easy': const LocalizedString({'en': 'easy'})},
    },
    allAvoidableFlags: {'dairy', 'nuts', 'vegan'},
  );
}

void main() {
  group('RecipeMatcher', () {
    test('visible when no conflict', () {
      final matcher = RecipeMatcher(ontology: _ontology(), ingredientTree: null);
      final profile = Profile();
      final recipe = _recipe();
      expect(matcher.visible(recipe, profile), true);
    });

    test('hidden by avoid flag', () {
      final matcher = RecipeMatcher(ontology: _ontology(), ingredientTree: null);
      final profile = Profile(avoidFlags: {'dairy'});
      final recipe = _recipe(contains: ['dairy']);
      expect(matcher.visible(recipe, profile), false);
    });

    test('compound flag expands', () {
      final matcher = RecipeMatcher(ontology: _ontology(), ingredientTree: null);
      final profile = Profile(avoidFlags: {'vegan'});
      final recipe = _recipe(contains: ['dairy']);
      expect(matcher.visible(recipe, profile), false);
    });

    test('hidden by time budget', () {
      final matcher = RecipeMatcher(ontology: _ontology(), ingredientTree: null);
      final profile = Profile(maxTimeMinutes: 20);
      final recipe = _recipe(time: 30);
      expect(matcher.visible(recipe, profile), false);
    });

    test('hidden by specific ingredient via tree', () {
      final root = IngredientNode(
        id: 'root',
        name: const LocalizedString({'en': 'root'}),
        children: [
          IngredientNode(
            id: 'dairy',
            name: const LocalizedString({'en': 'dairy'}),
            children: [
              IngredientNode(id: 'milk', name: const LocalizedString({'en': 'milk'})),
            ],
          ),
        ],
      );
      final tree = AvoidanceTree(root);
      final matcher = RecipeMatcher(ontology: _ontology(), ingredientTree: tree);
      final profile = Profile(avoidIngredients: {'dairy'});
      final recipe = _recipe(ingredientIds: ['milk']);
      expect(matcher.visible(recipe, profile), false);
    });
  });
}
