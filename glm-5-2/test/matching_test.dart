import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/core/matching.dart';
import 'package:morphcook/models/models.dart';
import 'package:morphcook/models/profile.dart';

Recipe _recipe({
  required String id,
  List<String> contains = const [],
  List<String> ingredientIds = const [],
  int timeMinutes = 30,
  int calories = 500,
  String effort = 'medium',
  List<String> techniques = const ['sauté'],
  List<String> mealTypes = const ['dinner'],
  Map<String, dynamic> attributes = const {},
}) =>
    Recipe(
      id: id,
      dishId: 'd',
      title: {'en': 't'},
      diet: 'classic',
      effort: effort,
      calorieLevel: 'low',
      extraTags: const [],
      contains: contains,
      attributes: {
        'effort': effort,
        'time_bucket': '<=30',
        'calorie_bucket': '<=600',
        'technique': techniques,
        'meal_type': mealTypes,
        ...attributes,
      },
      timeMinutes: timeMinutes,
      caloriesPerServing: calories,
      macros: const {},
      servings: 4,
      ingredients: ingredientIds
          .map((id) => Ingredient(id: id, name: {'en': id}, quantity: 1, unit: 'g', aisle: 'pantry'))
          .toList(),
      steps: const [],
      tags: const [],
      cuisineTags: const [],
      frequencyTier: 'core',
    );

Ontology _ontology() => Ontology.fromJson({
      'contains_flags': ['dairy', 'gluten', 'pork', 'nuts'],
      'compound_flags': {
        'vegan': ['dairy', 'pork'],
        'vegetarian': ['pork'],
      },
      'attributes': {'effort': ['easy', 'medium']},
      'diets': ['classic', 'vegan'],
      'sparse_extras': ['gluten-free'],
    });

void main() {
  group('matchRecipe', () {
    test('visible when no conflicts', () {
      final r = _recipe(id: 'r');
      final m = matchRecipe(r, const Profile(), _ontology());
      expect(m.visible, true);
    });

    test('hidden when contains intersects expanded avoid flags', () {
      final r = _recipe(id: 'r', contains: ['dairy']);
      final p = const Profile(avoidFlags: {'vegan'});
      final m = matchRecipe(r, p, _ontology());
      expect(m.visible, false);
      expect(m.conflictFlags, contains('dairy'));
    });

    test('hidden when avoid ingredient matches', () {
      final r = _recipe(id: 'r', ingredientIds: ['apples']);
      final p = const Profile(avoidIngredients: {'apples'});
      expect(matchRecipe(r, p, _ontology()).visible, false);
    });

    test('hidden when time exceeds budget', () {
      final r = _recipe(id: 'r', timeMinutes: 90);
      final p = const Profile(maxTimeMinutes: 60);
      expect(matchRecipe(r, p, _ontology()).visible, false);
    });

    test('hidden when calories outside tolerance', () {
      final r = _recipe(id: 'r', calories: 1000);
      final p = const Profile(calorieTarget: 400, calorieTolerance: 100);
      expect(matchRecipe(r, p, _ontology()).visible, false);
    });

    test('filters can be ignored per-call', () {
      final r = _recipe(id: 'r', timeMinutes: 90, calories: 1000);
      final p = const Profile(maxTimeMinutes: 60, calorieTarget: 400, calorieTolerance: 100);
      expect(matchRecipe(r, p, _ontology(), ignoreTimeFilter: true, ignoreCalorieFilter: true).visible, true);
    });
  });

  group('timeOfDayBonus', () {
    test('breakfast bonus in morning', () {
      final r = _recipe(id: 'r', mealTypes: ['breakfast']);
      final morning = DateTime(2026, 1, 1, 8);
      expect(timeOfDayBonus(r, morning), greaterThan(0));
    });

    test('dinner bonus in evening', () {
      final r = _recipe(id: 'r', mealTypes: ['dinner']);
      final evening = DateTime(2026, 1, 1, 19);
      expect(timeOfDayBonus(r, evening), greaterThan(0));
    });

    test('no bonus at unrelated time', () {
      final r = _recipe(id: 'r', mealTypes: ['dinner']);
      final morning = DateTime(2026, 1, 1, 8);
      expect(timeOfDayBonus(r, morning), 0);
    });
  });

  group('stalenessBonus', () {
    test('zero when never cooked', () {
      expect(stalenessBonus(null), 0);
    });

    test('bonus when 30+ days ago', () {
      final old = DateTime.now().subtract(const Duration(days: 45));
      expect(stalenessBonus(old), 50);
    });

    test('no bonus when recently cooked', () {
      final recent = DateTime.now().subtract(const Duration(days: 5));
      expect(stalenessBonus(recent), 0);
    });
  });

  group('pickBestVariant', () {
    test('returns null when none visible', () {
      final variants = [
        _recipe(id: 'a', contains: ['dairy']),
        _recipe(id: 'b', contains: ['pork']),
      ];
      final p = const Profile(avoidFlags: {'vegan'});
      expect(pickBestVariant(variants, p, _ontology()), isNull);
    });

    test('prefers matching effort', () {
      final variants = [
        _recipe(id: 'a', effort: 'easy', calories: 600),
        _recipe(id: 'b', effort: 'medium', calories: 600),
      ];
      final p = const Profile(preferredEffort: 'medium', calorieTarget: 600, calorieTolerance: 200);
      final best = pickBestVariant(variants, p, _ontology());
      expect(best?.id, 'b');
    });
  });

  group('Ontology.expandAvoidFlags', () {
    test('expands compound flags', () {
      final o = _ontology();
      final expanded = o.expandAvoidFlags({'vegan'});
      expect(expanded, containsAll(['dairy', 'pork']));
    });

    test('keeps simple flags as-is', () {
      final o = _ontology();
      final expanded = o.expandAvoidFlags({'gluten'});
      expect(expanded, {'gluten'});
    });
  });
}
