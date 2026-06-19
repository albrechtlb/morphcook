import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';
import '../models/models_all.dart';

class Corpus {
  final List<Recipe> recipes;
  final List<Dish> dishes;
  final Ontology ontology;
  final IngredientTree ingredientTree;
  final List<FaqEntry> faqs;
  final List<IngredientGuideEntry> ingredientGuide;
  final Map<String, Recipe> recipeIndex;
  final Map<String, Dish> dishIndex;

  Corpus({
    required this.recipes,
    required this.dishes,
    required this.ontology,
    required this.ingredientTree,
    required this.faqs,
    required this.ingredientGuide,
  })  : recipeIndex = {for (final r in recipes) r.id: r},
        dishIndex = {for (final d in dishes) d.id: d};

  static Future<Corpus> load() async {
    final ontology = await _loadOntology();
    final dishes = await _loadDishes();
    final ingredients = await _loadIngredients();
    final faqs = await _loadFaqs();
    final guide = await _loadIngredientGuide();
    final recipes = await _loadAllRecipes();

    return Corpus(
      recipes: recipes,
      dishes: dishes,
      ontology: ontology,
      ingredientTree: ingredients,
      faqs: faqs,
      ingredientGuide: guide,
    );
  }

  static Future<Ontology> _loadOntology() async {
    final s = await rootBundle.loadString('assets/ontology.json');
    return Ontology.fromJson(json.decode(s) as Map<String, dynamic>);
  }

  static Future<List<Dish>> _loadDishes() async {
    final s = await rootBundle.loadString('assets/dishes.json');
    final j = json.decode(s) as Map<String, dynamic>;
    return (j['dishes'] as List).map((e) => Dish.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<IngredientTree> _loadIngredients() async {
    final s = await rootBundle.loadString('assets/ingredients.json');
    return IngredientTree.fromJson(json.decode(s) as Map<String, dynamic>);
  }

  static Future<List<FaqEntry>> _loadFaqs() async {
    final s = await rootBundle.loadString('assets/faqs.json');
    final j = json.decode(s) as Map<String, dynamic>;
    return (j['entries'] as List).map((e) => FaqEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<IngredientGuideEntry>> _loadIngredientGuide() async {
    final s = await rootBundle.loadString('assets/ingredient-guide.json');
    final j = json.decode(s) as Map<String, dynamic>;
    return (j['entries'] as List).map((e) => IngredientGuideEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Recipe>> _loadAllRecipes() async {
    // Load core (preload) + extended lazily too for v1 simplicity.
    final core = await _loadPartition('core-recipes.json');
    final extended = await _loadPartition('extended-recipes.json');
    return [...core, ...extended];
  }

  static Future<List<Recipe>> _loadPartition(String fileName) async {
    final s = await rootBundle.loadString('assets/partitions/$fileName');
    final j = json.decode(s) as Map<String, dynamic>;
    return (j['recipes'] as List).map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Dish? dishForRecipe(String recipeId) {
    final r = recipeIndex[recipeId];
    if (r == null) return null;
    return dishIndex[r.dishId];
  }
}
