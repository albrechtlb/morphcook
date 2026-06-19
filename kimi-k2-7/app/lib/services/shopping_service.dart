import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../models/shopping_and_backup.dart';
import 'corpus_service.dart';
import 'data_store_service.dart';

const _volumeUnits = {'ml': 1.0, 'tbsp': 15.0, 'tsp': 5.0};

const _aisleMap = {
  'produce': ['tomato', 'onion', 'garlic', 'cucumber', 'lemon', 'cilantro', 'lime', 'ginger', 'kale', 'sweet-potato', 'bell-peppers', 'apples', 'potato'],
  'dairy': ['yogurt', 'cheese', 'parmesan', 'feta', 'butter', 'cream', 'milk'],
  'meat-fish': ['beef', 'lamb', 'pork', 'chicken', 'turkey', 'shrimp', 'salmon', 'fish'],
  'pantry': ['tahini', 'soy-sauce', 'sesame', 'sugar', 'honey', 'olive-oil', 'tamarind', 'cumin', 'paprika', 'nutritional-yeast'],
  'grains-bakery': ['pita-bread', 'pasta', 'rice', 'rice-noodles', 'quinoa', 'oats', 'bread'],
};

class ShoppingService extends ChangeNotifier {
  final CorpusService corpus;
  final DataStoreService store;

  List<ShoppingItem> _items = [];

  ShoppingService({required this.corpus, required this.store}) {
    _load();
  }

  List<ShoppingItem> get items => List.unmodifiable(_items);

  void _load() {
    final json = store.shoppingJson;
    if (json == null || json.isEmpty) {
      _items = [];
      return;
    }
    try {
      final decoded = jsonDecode(json) as List? ?? [];
      _items = decoded
          .whereType<Map>()
          .map((e) => _itemFromMap(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      _items = [];
    }
  }

  Future<void> _persist() async {
    await store.setShoppingJson(jsonEncode(_items.map(_itemToMap).toList()));
    notifyListeners();
  }

  Future<void> addRecipe(Recipe recipe, {double scale = 1.0}) async {
    final additions = _ingredientsToItems(recipe, scale);
    final merged = [..._items];
    for (final add in additions) {
      final idx = merged.indexWhere((i) => _canMerge(i, add));
      if (idx >= 0) {
        merged[idx] = _merge(merged[idx], add);
      } else {
        merged.add(add);
      }
    }
    _items = merged;
    await _persist();
  }

  Future<void> removeItem(String ingredientId) async {
    _items.removeWhere((i) => i.ingredientId == ingredientId);
    await _persist();
  }

  Future<void> updateQuantity(String ingredientId, double quantity) async {
    final idx = _items.indexWhere((i) => i.ingredientId == ingredientId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
      await _persist();
    }
  }

  Future<void> clear() async {
    _items = [];
    await _persist();
  }

  Future<void> replaceFromRecipeIds(List<String> ids, {double scale = 1.0}) async {
    _items = [];
    for (final id in ids) {
      final recipe = corpus.recipeById(id);
      if (recipe != null) {
        _items.addAll(_ingredientsToItems(recipe, scale));
      }
    }
    _items = _dedupe(_items);
    await _persist();
  }

  ShoppingInsights generateInsights() {
    final counts = <String, int>{};
    final monthly = <String, int>{};
    final aisleCounts = <String, int>{};
    for (final item in _items) {
      counts[item.displayName] = (counts[item.displayName] ?? 0) + 1;
      aisleCounts[item.aisle] = (aisleCounts[item.aisle] ?? 0) + 1;
      final month = DateTime.now().toIso8601String().substring(0, 7);
      monthly[month] = (monthly[month] ?? 0) + 1;
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ShoppingInsights(
      uniqueIngredientCount: counts.length,
      topIngredients: top.take(5).toList(),
      monthlyCounts: monthly,
      topAisles: aisleCounts,
    );
  }

  List<ShoppingItem> _ingredientsToItems(Recipe recipe, double scale) {
    return recipe.ingredients.map((ing) {
      final baseQty = ing.quantity ?? 0;
      final qty = baseQty * scale;
      return ShoppingItem(
        ingredientId: ing.ingredientId,
        displayName: ing.name.text('en'),
        quantity: qty,
        unit: ing.unit,
        aisle: _detectAisle(ing.ingredientId),
        optional: ing.optional,
        fromRecipes: {recipe.id},
      );
    }).toList();
  }

  bool _canMerge(ShoppingItem a, ShoppingItem b) {
    return a.ingredientId == b.ingredientId && a.unit == b.unit;
  }

  ShoppingItem _merge(ShoppingItem a, ShoppingItem b) {
    double qty = a.quantity;
    var unit = a.unit;
    if (a.unit == b.unit) {
      qty = a.quantity + b.quantity;
    } else {
      final aBase = _toMl(a.quantity, a.unit);
      final bBase = _toMl(b.quantity, b.unit);
      if (aBase != null && bBase != null) {
        final total = aBase + bBase;
        unit = 'ml';
        qty = total;
      }
    }
    return ShoppingItem(
      ingredientId: a.ingredientId,
      displayName: a.displayName,
      quantity: qty,
      unit: unit,
      aisle: a.aisle,
      optional: a.optional && b.optional,
      fromRecipes: {...a.fromRecipes, ...b.fromRecipes},
    );
  }

  List<ShoppingItem> _dedupe(List<ShoppingItem> items) {
    final merged = <ShoppingItem>[];
    for (final item in items) {
      final idx = merged.indexWhere((m) => _canMerge(m, item));
      if (idx >= 0) {
        merged[idx] = _merge(merged[idx], item);
      } else {
        merged.add(item);
      }
    }
    return merged;
  }

  double? _toMl(double qty, String? unit) {
    return _volumeUnits[unit]?.let((factor) => qty * factor);
  }

  String _detectAisle(String ingredientId) {
    for (final entry in _aisleMap.entries) {
      if (entry.value.contains(ingredientId)) return entry.key;
    }
    return 'other';
  }

  static Map<String, dynamic> _itemToMap(ShoppingItem item) => {
        'ingredient_id': item.ingredientId,
        'display_name': item.displayName,
        'quantity': item.quantity,
        if (item.unit != null) 'unit': item.unit,
        'aisle': item.aisle,
        'optional': item.optional,
        'from_recipes': item.fromRecipes.toList(),
      };

  static ShoppingItem _itemFromMap(Map<String, dynamic> map) => ShoppingItem(
        ingredientId: map['ingredient_id'] as String? ?? '',
        displayName: map['display_name'] as String? ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unit: map['unit'] as String?,
        aisle: map['aisle'] as String? ?? 'other',
        optional: map['optional'] as bool? ?? false,
        fromRecipes: ((map['from_recipes'] as List? ?? [])).map((e) => e.toString()).toSet(),
      );
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
