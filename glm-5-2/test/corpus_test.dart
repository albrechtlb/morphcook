import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ontology loads and parses', () async {
    final s = await rootBundle.loadString('assets/ontology.json');
    final j = json.decode(s) as Map<String, dynamic>;
    final o = Ontology.fromJson(j);
    expect(o.containsFlags, contains('dairy'));
    expect(o.compoundFlags['vegan'], contains('dairy'));
  });

  test('dishes load and parse', () async {
    final s = await rootBundle.loadString('assets/dishes.json');
    final j = json.decode(s) as Map<String, dynamic>;
    final dishes = (j['dishes'] as List).map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
    expect(dishes.length, greaterThan(0));
    final doener = dishes.firstWhere((d) => d.id == 'doener');
    expect(doener.variantRecipeIds.length, greaterThan(0));
  });

  test('all recipes parse', () async {
    final s = await rootBundle.loadString('assets/partitions/core-recipes.json');
    final j = json.decode(s) as Map<String, dynamic>;
    final recipes = (j['recipes'] as List).map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
    expect(recipes.length, greaterThan(20));
    for (final r in recipes) {
      expect(r.id, isNotEmpty);
      expect(r.dishId, isNotEmpty);
      expect(r.ingredients.length, greaterThan(0));
      expect(r.steps.length, greaterThan(0));
    }
  });
}
