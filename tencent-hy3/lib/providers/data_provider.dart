import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../models/recipe.dart';
import '../models/dish.dart';
import '../models/ontology.dart';

class DataProvider extends ChangeNotifier {
  Profile _profile = Profile();
  List<Recipe> _recipes = [];
  List<Dish> _dishes = [];
  Ontology? _ontology;
  bool _isLoaded = false;
  bool _isOnboardingComplete = false;

  Profile get profile => _profile;
  List<Recipe> get recipes => _recipes;
  List<Dish> get dishes => _dishes;
  Ontology? get ontology => _ontology;
  bool get isLoaded => _isLoaded;
  bool get isOnboardingComplete => _isOnboardingComplete;

  Future<void> initialize() async {
    await _loadProfile();
    await _loadAssets();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final profileJson = prefs.getString('profile');
    if (profileJson != null) {
      // Parse profile from JSON
    }
  }

  Future<void> _loadAssets() async {
    // In production, load from assets/
    // For now, using sample data
  }

  void updateProfile(Profile profile) {
    _profile = profile;
    _saveProfile();
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile', _profile.toJson().toString());
  }

  void completeOnboarding() {
    _isOnboardingComplete = true;
    notifyListeners();
  }

  List<Recipe> getVisibleRecipes() {
    if (_ontology == null) return _recipes;
    return _recipes
        .where((recipe) => _ontology!.recipeMatchesProfile(recipe, _profile))
        .toList();
  }

  List<Dish> getVisibleDishes() {
    final visibleRecipeIds = getVisibleRecipes().map((r) => r.id).toSet();
    return _dishes
        .where((dish) =>
            dish.variantRecipeIds.any((id) => visibleRecipeIds.contains(id)))
        .toList();
  }

  Recipe? getRecipeById(String id) {
    return _recipes.where((r) => r.id == id).firstOrNull;
  }

  Dish? getDishById(String id) {
    return _dishes.where((d) => d.id == id).firstOrNull;
  }

  List<Recipe> getRecipesForDish(String dishId) {
    final dish = getDishById(dishId);
    if (dish == null) return [];
    return dish.variantRecipeIds
        .map((id) => getRecipeById(id))
        .whereType<Recipe>()
        .toList();
  }
}
