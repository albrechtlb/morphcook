import 'dart:convert';

enum ShoppingSlot {
  breakfast('breakfast'),
  lunch('lunch'),
  dinner('dinner');

  final String key;
  const ShoppingSlot(this.key);
}

class MealPlanEntry {
  final DateTime date;
  final ShoppingSlot slot;
  String recipeId;

  MealPlanEntry({
    required this.date,
    required this.slot,
    required this.recipeId,
  });

  String get key {
    final iso = date.toIso8601String().split('T').first;
    return '$iso.${slot.key}';
  }

  static MealPlanEntry? parseKey(String key, {required Map<String, String> recipeIdsByKey}) {
    final parts = key.split('.');
    if (parts.length != 2) return null;
    final date = DateTime.tryParse(parts[0]);
    final slot = ShoppingSlot.values.where((s) => s.key == parts[1]).firstOrNull;
    if (date == null || slot == null) return null;
    return MealPlanEntry(
      date: date,
      slot: slot,
      recipeId: recipeIdsByKey[key] ?? '',
    );
  }
}

class ShoppingItem {
  final String ingredientId;
  final String displayName;
  final double quantity;
  final String? unit;
  final String aisle;
  final bool optional;
  final Set<String> fromRecipes;

  ShoppingItem({
    required this.ingredientId,
    required this.displayName,
    required this.quantity,
    this.unit,
    required this.aisle,
    this.optional = false,
    required this.fromRecipes,
  });

  ShoppingItem copyWith({
    double? quantity,
    Set<String>? fromRecipes,
  }) {
    return ShoppingItem(
      ingredientId: ingredientId,
      displayName: displayName,
      quantity: quantity ?? this.quantity,
      unit: unit,
      aisle: aisle,
      optional: optional,
      fromRecipes: fromRecipes ?? this.fromRecipes,
    );
  }
}

class ShoppingList {
  final List<ShoppingItem> items;
  final DateTime updatedAt;

  ShoppingList({required this.items, required this.updatedAt});
}

class ShoppingInsights {
  final int uniqueIngredientCount;
  final List<MapEntry<String, int>> topIngredients;
  final Map<String, int> monthlyCounts;
  final Map<String, int> topAisles;

  ShoppingInsights({
    required this.uniqueIngredientCount,
    required this.topIngredients,
    required this.monthlyCounts,
    required this.topAisles,
  });
}

class BackupData {
  final int schemaVersion;
  final DateTime exportedAt;
  final Map<String, dynamic> profile;
  final List<String> saved;
  final Map<String, String> mealPlan;
  final Map<String, String> history;
  final List<String> contentRequests;

  BackupData({
    this.schemaVersion = 1,
    required this.exportedAt,
    required this.profile,
    required this.saved,
    required this.mealPlan,
    required this.history,
    required this.contentRequests,
  });

  Map<String, dynamic> toMap() => {
        'schema_version': schemaVersion,
        'exported_at': exportedAt.toUtc().toIso8601String(),
        'profile': profile,
        'saved': saved,
        'meal_plan': mealPlan,
        'history': history,
        'content_requests': contentRequests,
      };

  factory BackupData.fromMap(Map<String, dynamic> map) {
    Map<String, String> parseHistory(dynamic raw) {
      if (raw is Map) {
        return raw.cast<String, String>();
      }
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        return raw.first.cast<String, String>();
      }
      return {};
    }

    return BackupData(
      schemaVersion: map['schema_version'] as int? ?? 1,
      exportedAt: DateTime.tryParse(map['exported_at'] as String? ?? '') ?? DateTime.now().toUtc(),
      profile: (map['profile'] as Map?)?.cast<String, dynamic>() ?? {},
      saved: (map['saved'] as List? ?? []).map((e) => e.toString()).toList(),
      mealPlan: (map['meal_plan'] as Map?)?.cast<String, String>() ?? {},
      history: parseHistory(map['history']),
      contentRequests: (map['content_requests'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  String toJsonString() => jsonEncode(toMap());
}
