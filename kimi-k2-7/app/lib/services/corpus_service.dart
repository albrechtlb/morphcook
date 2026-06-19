import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/dish.dart';
import '../models/faq.dart';
import '../models/ingredient.dart';
import '../models/ontology.dart';
import '../models/recipe.dart';

class CorpusService {
  List<Recipe> recipes = [];
  List<Dish> dishes = [];
  Ontology? ontology;
  AvoidanceTree? ingredientTree;
  FAQList? faqList;

  final _partitionLoaded = <String, bool>{};

  Future<void> loadCore() async {
    await Future.wait([
      _loadOntology(),
      _loadIngredients(),
      _loadFAQs(),
      _loadDishes(),
      loadPartition('core'),
    ]);
  }

  Future<void> _loadOntology() async {
    final raw = await rootBundle.loadString('assets/ontology.json');
    ontology = Ontology.fromMap(jsonDecode(raw));
  }

  Future<void> _loadIngredients() async {
    final raw = await rootBundle.loadString('assets/ingredients.json');
    ingredientTree = AvoidanceTree.fromMap(jsonDecode(raw));
  }

  Future<void> _loadFAQs() async {
    final raw = await rootBundle.loadString('assets/faqs.json');
    faqList = FAQList.fromMap(jsonDecode(raw));
  }

  Future<void> _loadDishes() async {
    final raw = await rootBundle.loadString('assets/dishes.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    dishes = (map['dishes'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Dish.fromMap(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> loadPartition(String partitionId) async {
    if (_partitionLoaded[partitionId] == true) return;
    final manifest = await rootBundle.loadString('assets/partition-manifest.json');
    final decoded = jsonDecode(manifest) as Map<String, dynamic>;
    final partitions = (decoded['partitions'] as List? ?? []).cast<Map<String, dynamic>>();
    final entry = partitions.firstWhere(
      (p) => p['id'] == partitionId,
      orElse: () => <String, dynamic>{},
    );
    final file = entry['file'] as String?;
    if (file == null) return;
    final raw = await rootBundle.loadString('assets/$file');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final newRecipes = (map['recipes'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Recipe.fromMap(e.cast<String, dynamic>()))
        .toList();
    recipes.removeWhere((r) => r.partitionId == partitionId);
    recipes.addAll(newRecipes);
    _partitionLoaded[partitionId] = true;
  }

  Recipe? recipeById(String id) {
    try {
      return recipes.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Recipe> recipesForDish(String dishId) {
    return recipes.where((r) => r.dishId == dishId).toList();
  }

  Dish? dishById(String id) {
    try {
      return dishes.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Recipe> recipesFromIds(List<String> ids) {
    return ids.map(recipeById).whereType<Recipe>().toList();
  }
}
