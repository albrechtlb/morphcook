import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DataStoreService extends ChangeNotifier {
  static const _savedBox = 'saved_recipes';
  static const _historyBox = 'history';
  static const _mealPlanBox = 'meal_plan';
  static const _shoppingBox = 'shopping';
  static const _requestsBox = 'content_requests';

  Box<String>? _saved;
  Box<String>? _history;
  Box<String>? _mealPlan;
  Box<String>? _shopping;
  Box<String>? _requests;

  Future<void> init() async {
    await Hive.initFlutter();
    _saved = await Hive.openBox<String>(_savedBox);
    _history = await Hive.openBox<String>(_historyBox);
    _mealPlan = await Hive.openBox<String>(_mealPlanBox);
    _shopping = await Hive.openBox<String>(_shoppingBox);
    _requests = await Hive.openBox<String>(_requestsBox);
    notifyListeners();
  }

  // Saved recipes
  List<String> get savedRecipeIds => _saved?.values.toList() ?? [];

  bool isSaved(String recipeId) => _saved?.containsKey(recipeId) ?? false;

  Future<void> toggleSaved(String recipeId) async {
    if (isSaved(recipeId)) {
      await _saved?.delete(recipeId);
    } else {
      await _saved?.put(recipeId, recipeId);
    }
    notifyListeners();
  }

  Future<void> clearSaved() async {
    await _saved?.clear();
    notifyListeners();
  }

  // History
  DateTime? lastCooked(String recipeId) {
    final raw = _history?.get(recipeId);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Map<String, DateTime> get lastCookedMap {
    final map = <String, DateTime>{};
    _history?.toMap().forEach((id, raw) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) map[id] = dt;
    });
    return map;
  }

  Future<void> recordCooked(String recipeId, {DateTime? when}) async {
    await _history?.put(recipeId, (when ?? DateTime.now()).toIso8601String());
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _history?.clear();
    notifyListeners();
  }

  // Meal plan
  Map<String, String> get mealPlan {
    final map = <String, String>{};
    _mealPlan?.toMap().forEach((k, v) => map[k] = v);
    return map;
  }

  Future<void> setMealPlan(String key, String recipeId) async {
    await _mealPlan?.put(key, recipeId);
    notifyListeners();
  }

  Future<void> removeMealPlan(String key) async {
    await _mealPlan?.delete(key);
    notifyListeners();
  }

  Future<void> clearMealPlan() async {
    await _mealPlan?.clear();
    notifyListeners();
  }

  Future<void> moveMealPlan(String fromKey, String toKey) async {
    final value = _mealPlan?.get(fromKey);
    if (value == null) return;
    await _mealPlan?.delete(fromKey);
    await _mealPlan?.put(toKey, value);
    notifyListeners();
  }

  // Shopping
  String? get shoppingJson => _shopping?.get('current');

  Future<void> setShoppingJson(String json) async {
    await _shopping?.put('current', json);
    notifyListeners();
  }

  Future<void> clearShopping() async {
    await _shopping?.delete('current');
    notifyListeners();
  }

  // Content requests
  List<String> get contentRequests => _requests?.values.toList() ?? [];

  Future<void> addContentRequest(String query) async {
    final key = query.toLowerCase().trim();
    if (key.isEmpty) return;
    await _requests?.put(key, query);
    notifyListeners();
  }

  Future<void> clearContentRequests() async {
    await _requests?.clear();
    notifyListeners();
  }

  // Bulk export maps
  Map<String, String> get exportState => {
        'saved': jsonEncode(savedRecipeIds),
        'history': jsonEncode(lastCookedMap.map((k, v) => MapEntry(k, v.toIso8601String()))),
        'meal_plan': jsonEncode(mealPlan),
        'content_requests': jsonEncode(contentRequests),
      };

  Future<void> importState({
    List<String>? saved,
    Map<String, DateTime>? history,
    Map<String, String>? mealPlan,
    List<String>? contentRequests,
    bool replace = false,
  }) async {
    if (replace) {
      await _saved?.clear();
      await _history?.clear();
      await _mealPlan?.clear();
      await _requests?.clear();
    }
    if (saved != null) {
      for (final id in saved) {
        await _saved?.put(id, id);
      }
    }
    if (history != null) {
      for (final e in history.entries) {
        await _history?.put(e.key, e.value.toIso8601String());
      }
    }
    if (mealPlan != null) {
      for (final e in mealPlan.entries) {
        await _mealPlan?.put(e.key, e.value);
      }
    }
    if (contentRequests != null) {
      for (final q in contentRequests) {
        final key = q.toLowerCase().trim();
        await _requests?.put(key, q);
      }
    }
    notifyListeners();
  }
}
