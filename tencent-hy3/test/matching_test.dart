import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/models/recipe.dart';
import 'package:morphcook/models/profile.dart';
import 'package:morphcook/models/ontology.dart';

void main() {
  group('Matching Algorithm Tests', () {
    late Ontology ontology;
    late Profile profile;
    late Recipe veganRecipe;
    late Recipe classicRecipe;

    setUp(() {
      ontology = Ontology(
        version: '1.0.0',
        containsFlags: ['beef', 'dairy', 'gluten', 'soy', 'pork'],
        compoundAvoidFlags: {
          'vegan': ['beef', 'dairy', 'pork'],
        },
        attributes: {
          'effort': ['easy', 'medium', 'hard'],
          'time_bucket': ['≤15', '≤30', '≤60', '>60'],
          'calorie_bucket': ['≤400', '≤600', '≤800', '>800'],
          'technique': ['bake', 'sauté', 'simmer'],
        },
        dietDimensions: ['classic', 'vegan', 'vegetarian'],
        calorieLevels: ['≤400', '≤600', '≤800', '>800'],
      );

      profile = Profile(
        avoidFlags: {'beef', 'dairy'},
        calorieTarget: 600,
        maxTimeMinutes: 60,
      );

      veganRecipe = Recipe(
        id: 'doener-vegan',
        dishId: 'doener',
        variantLabel: {'en': 'Vegan', 'de': 'Vegan'},
        diet: 'vegan',
        effort: 'easy',
        timeMinutes: 25,
        caloriesPerServing: 480,
        contains: ['soy', 'gluten'],
        attributes: ['easy', '≤30', '≤600'],
        servings: 2,
        ingredients: [],
        steps: [],
        tags: ['vegan'],
      );

      classicRecipe = Recipe(
        id: 'doener-classic',
        dishId: 'doener',
        variantLabel: {'en': 'Classic', 'de': 'Klassisch'},
        diet: 'classic',
        effort: 'easy',
        timeMinutes: 25,
        caloriesPerServing: 620,
        contains: ['beef', 'dairy', 'gluten'],
        attributes: ['easy', '≤30', '≤800'],
        servings: 2,
        ingredients: [],
        steps: [],
        tags: ['classic'],
      );
    });

    test('recipe with avoided flags should not match', () {
      final result = ontology.recipeMatchesProfile(classicRecipe, profile);
      expect(result, false);
    });

    test('recipe without avoided flags should match', () {
      final result = ontology.recipeMatchesProfile(veganRecipe, profile);
      expect(result, true);
    });

    test('recipe exceeding time budget should not match', () {
      profile.maxTimeMinutes = 15;
      final result = ontology.recipeMatchesProfile(veganRecipe, profile);
      expect(result, false);
    });

    test('recipe outside calorie target should not match', () {
      profile.calorieTarget = 300;
      final result = ontology.recipeMatchesProfile(veganRecipe, profile);
      expect(result, false);
    });

    test('expand compound flag should return all sub-flags', () {
      final expanded = ontology.expandCompoundFlag('vegan');
      expect(expanded, contains('beef'));
      expect(expanded, contains('dairy'));
      expect(expanded, contains('pork'));
    });
  });
}
