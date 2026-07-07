import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RootScreen rebuilds on state changes: onboarding -> feed -> cookbook, '
    'and unknown saved ids do not crash the cookbook',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final app = AppState();
      await app.load();
      // A saved id that is not in the bundled corpus must not crash Cookbook.
      app.saved.add('this-recipe-does-not-exist');

      await tester.pumpWidget(
        AppScope(
          app: app,
          child: const MaterialApp(home: RootScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Starts on onboarding; the feed is not shown yet.
      expect(find.text('MORPHCOOK EVENING EDITION'), findsNothing);

      // This is exactly what the "open cookbook" button does. Flipping
      // onboarded must rebuild the const RootScreen (regression: it used to
      // stay stuck because the InheritedWidget never notified dependents).
      app.completeOnboarding(app.profile.copyWith(name: 'Mira'));
      await tester.pumpAndSettle();
      expect(app.profile.onboarded, isTrue);
      expect(find.text('morphcook'), findsOneWidget);
      expect(find.text('MORPHCOOK EVENING EDITION'), findsOneWidget);
      expect(find.text('TODAY\'S COMPLETE DISHES'), findsOneWidget);

      // Switching tabs must also rebuild the body (same dead-notifier bug),
      // and the cookbook must render despite the unknown saved id.
      app.setTab(2);
      await tester.pumpAndSettle();
      expect(app.tab, 2);
      expect(find.text('your saved variants'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Drain the fire-and-forget persist() future before teardown.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    },
  );

  test(
    'matching respects avoid flags, ingredients, time, attributes, and calories',
    () {
      final ontology = Ontology(
        {
          'vegan': {'dairy', 'egg'},
        },
        ['dairy', 'egg'],
        ['easy'],
        ['600'],
      );
      final profile = Profile.defaultProfile().copyWith(
        avoidFlags: {'vegan'},
        avoidIngredients: {'cilantro'},
        requiredAttributes: {'easy'},
        maxTimeMinutes: 30,
        calorieTarget: 600,
      );
      final recipe = Recipe(
        id: 'r',
        dishId: 'd',
        title: {'en': 'test'},
        diet: 'classic',
        effort: 'easy',
        calorieLevel: '600',
        calories: 610,
        timeMinutes: 20,
        servings: 1,
        contains: {},
        attributes: {'easy'},
        tags: [],
        mealTypes: ['dinner'],
        ingredients: [
          RecipeIngredient(
            id: 'garlic',
            name: {'en': 'garlic'},
            amount: 2,
            unit: 'clove',
            aisle: 'produce',
          ),
        ],
        steps: [],
        macros: {},
      );

      expect(Matching.visible(recipe, profile, ontology), isTrue);
      expect(
        Matching.visible(recipe.copyWithContains({'dairy'}), profile, ontology),
        isFalse,
      );
    },
  );

  test('shopping list aggregates compatible units', () {
    final recipe = Recipe(
      id: 'r',
      dishId: 'd',
      title: {'en': 'test'},
      diet: 'classic',
      effort: 'easy',
      calorieLevel: '600',
      calories: 600,
      timeMinutes: 10,
      servings: 1,
      contains: {},
      attributes: {},
      tags: [],
      mealTypes: [],
      ingredients: [
        RecipeIngredient(
          id: 'garlic',
          name: {'en': 'garlic'},
          amount: 2,
          unit: 'clove',
          aisle: 'produce',
        ),
        RecipeIngredient(
          id: 'garlic',
          name: {'en': 'garlic'},
          amount: 3,
          unit: 'clove',
          aisle: 'produce',
        ),
        RecipeIngredient(
          id: 'oil',
          name: {'en': 'oil'},
          amount: 2,
          unit: 'tbsp',
          aisle: 'pantry',
        ),
      ],
      steps: [],
      macros: {},
    );

    final grouped = Shopping.aggregate([recipe]);
    expect(grouped['produce']!.single.amount, 5);
    expect(grouped['pantry']!.single.amount, 30);
    expect(grouped['pantry']!.single.unit, 'ml');
  });

  test('backup export contains required schema fields', () {
    final app = AppState();
    final data = jsonDecode(app.exportBackup()) as Map<String, dynamic>;
    expect(data['schema_version'], 1);
    expect(data['saved'], contains('doener-vegan-easy-600'));
    expect(data.containsKey('content_requests'), isTrue);
    final encrypted = app.exportBackup(password: 'secret');
    expect(encrypted.startsWith('ENC'), isTrue);
    expect(
      BackupService.parseText(encrypted, password: 'secret')['schema_version'],
      1,
    );
    expect(
      () => BackupService.parseText(encrypted, password: 'wrong'),
      throwsFormatException,
    );
  });

  test('corpus safe lookups return null for unknown ids', () {
    Recipe recipe(String id) => Recipe(
      id: id,
      dishId: 'doener',
      title: {'en': id},
      diet: 'vegan',
      effort: 'easy',
      calorieLevel: '600',
      calories: 600,
      timeMinutes: 20,
      servings: 1,
      contains: {},
      attributes: {},
      tags: [],
      mealTypes: [],
      ingredients: [],
      steps: [],
      macros: {},
    );
    final known = recipe('doener-vegan-easy-600');
    final dish = Dish(
      id: 'doener',
      name: {'en': 'döner'},
      hero: {'en': 'hero'},
      caption: {'en': 'cap'},
      stripe: const Color(0xff000000),
      recipeIds: [known.id],
      cuisineTags: const [],
    );
    final corpus = Corpus(
      dishes: [dish],
      recipes: [known],
      ontology: Ontology({}, [], [], []),
      ingredients: [],
      guides: [],
      faqs: [],
    );

    expect(corpus.recipeOrNull('nope-not-real'), isNull);
    expect(corpus.dishForRecipeOrNull('nope-not-real'), isNull);
    // Known ids still resolve.
    expect(corpus.recipeOrNull('doener-vegan-easy-600'), isNotNull);
    expect(corpus.dishForRecipeOrNull('doener-vegan-easy-600'), isNotNull);
  });

  test('completeOnboarding notifies listeners and sets onboarded', () {
    final app = AppState();
    var notified = 0;
    app.addListener(() => notified++);
    expect(app.profile.onboarded, isFalse);
    app.completeOnboarding(app.profile.copyWith(name: 'Mira'));
    expect(app.profile.onboarded, isTrue);
    expect(notified, greaterThan(0));
  });
}

extension on Recipe {
  Recipe copyWithContains(Set<String> contains) => Recipe(
    id: id,
    dishId: dishId,
    title: title,
    diet: diet,
    effort: effort,
    calorieLevel: calorieLevel,
    calories: calories,
    timeMinutes: timeMinutes,
    servings: servings,
    contains: contains,
    attributes: attributes,
    tags: tags,
    mealTypes: mealTypes,
    ingredients: ingredients,
    steps: steps,
    macros: macros,
  );
}
