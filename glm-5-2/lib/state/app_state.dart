import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/matching.dart';
import '../data/corpus.dart';
import '../models/models_all.dart';

/// Central app state. Holds corpus + profile + cookbook + meal plan + history +
/// content requests. Persisted via Hive boxes and SharedPreferences.
class AppState extends ChangeNotifier {
  final Corpus corpus;
  final SharedPreferences prefs;
  Profile _profile;
  final Box _cookbookBox;
  final Box _mealPlanBox;
  final Box _historyBox;
  final Box _requestsBox;

  AppState({
    required this.corpus,
    required this.prefs,
    required Profile profile,
    required Box cookbookBox,
    required Box mealPlanBox,
    required Box historyBox,
    required Box requestsBox,
  })  : _profile = profile,
        _cookbookBox = cookbookBox,
        _mealPlanBox = mealPlanBox,
        _historyBox = historyBox,
        _requestsBox = requestsBox;

  static Future<AppState> create(Corpus corpus) async {
    final prefs = await SharedPreferences.getInstance();
    await Hive.initFlutter();
    final cookbookBox = await Hive.openBox('cookbook');
    final mealPlanBox = await Hive.openBox('meal_plan');
    final historyBox = await Hive.openBox('history');
    final requestsBox = await Hive.openBox('requests');

    final profileJson = prefs.getString('profile');
    Profile profile;
    if (profileJson != null) {
      profile = Profile.fromJson(json.decode(profileJson) as Map<String, dynamic>);
    } else {
      profile = const Profile();
    }
    return AppState(
      corpus: corpus,
      prefs: prefs,
      profile: profile,
      cookbookBox: cookbookBox,
      mealPlanBox: mealPlanBox,
      historyBox: historyBox,
      requestsBox: requestsBox,
    );
  }

  Profile get profile => _profile;

  set profile(Profile p) {
    _profile = p;
    prefs.setString('profile', json.encode(p.toJson()));
    notifyListeners();
  }

  void updateProfile(Profile Function(Profile) updater) {
    profile = updater(_profile);
  }

  // ---- Cookbook (saved recipes) ----
  List<String> get savedRecipeIds => _cookbookBox.keys.map((e) => e.toString()).toList();

  bool isSaved(String recipeId) => _cookbookBox.containsKey(recipeId);

  void toggleSaved(String recipeId) {
    if (_cookbookBox.containsKey(recipeId)) {
      _cookbookBox.delete(recipeId);
    } else {
      _cookbookBox.put(recipeId, DateTime.now().toIso8601String());
    }
    notifyListeners();
  }

  List<({Recipe recipe, DateTime savedAt})> get savedRecipes {
    final entries = <({Recipe recipe, DateTime savedAt})>[];
    for (final key in _cookbookBox.keys) {
      final r = corpus.recipeIndex[key.toString()];
      if (r == null) continue;
      final savedAtStr = _cookbookBox.get(key) as String;
      entries.add((recipe: r, savedAt: DateTime.parse(savedAtStr)));
    }
    entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return entries;
  }

  // ---- Meal plan ----
  /// Meal plan: keys "YYYY-Www" -> { "mon.dinner": "recipe-id", ... }
  Map<String, Map<String, String>> get mealPlan {
    final out = <String, Map<String, String>>{};
    for (final key in _mealPlanBox.keys) {
      final v = _mealPlanBox.get(key);
      if (v is String) {
        out[key.toString()] = Map<String, String>.from(json.decode(v) as Map);
      } else if (v is Map) {
        out[key.toString()] = Map<String, String>.from(v);
      }
    }
    return out;
  }

  void assignMeal({required String weekKey, required String slot, required String? recipeId}) {
    final week = Map<String, String>.from(_mealPlanBox.get(weekKey) is String
        ? json.decode(_mealPlanBox.get(weekKey) as String) as Map
        : (_mealPlanBox.get(weekKey) as Map? ?? {}));
    if (recipeId == null) {
      week.remove(slot);
    } else {
      week[slot] = recipeId;
    }
    _mealPlanBox.put(weekKey, json.encode(week));
    notifyListeners();
  }

  String? mealFor(String weekKey, String slot) {
    final week = mealPlan[weekKey];
    return week?[slot];
  }

  void exportWeekToShoppingList(String weekKey, void Function(List<String> recipeIds) onExport) {
    final week = mealPlan[weekKey] ?? {};
    onExport(week.values.toList());
  }

  // ---- History ----
  List<({String recipeId, DateTime cookedAt})> get history {
    final raw = _historyBox.get('entries');
    List list;
    if (raw is String) {
      list = json.decode(raw) as List;
    } else if (raw is List) {
      list = raw;
    } else {
      list = const [];
    }
    final entries = <({String recipeId, DateTime cookedAt})>[];
    for (final e in list) {
      final m = e as Map;
      entries.add((recipeId: m['recipe_id'] as String, cookedAt: DateTime.parse(m['cooked_at'] as String)));
    }
    entries.sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
    return entries;
  }

  DateTime? lastCookedAt(String recipeId) {
    for (final e in history) {
      if (e.recipeId == recipeId) return e.cookedAt;
    }
    return null;
  }

  void recordCooked(String recipeId) {
    final entries = history.map((e) => {'recipe_id': e.recipeId, 'cooked_at': e.cookedAt.toIso8601String()}).toList();
    entries.insert(0, {'recipe_id': recipeId, 'cooked_at': DateTime.now().toIso8601String()});
    _historyBox.put('entries', json.encode(entries));
    notifyListeners();
  }

  // ---- Content requests ----
  List<String> get contentRequests {
    final raw = _requestsBox.get('entries');
    if (raw is String) return List<String>.from(json.decode(raw) as List);
    if (raw is List) return List<String>.from(raw);
    return const [];
  }

  void logContentRequest(String query) {
    final entries = contentRequests;
    if (entries.contains(query)) return;
    entries.add(query);
    _requestsBox.put('entries', json.encode(entries));
  }

  // ---- Matching helpers (UI-facing) ----
  List<({Dish dish, Recipe? bestVariant, List<Recipe> visibleVariants})> get visibleDishesNow =>
      visibleDishes(corpus.dishes, corpus.recipeIndex, _profile, corpus.ontology,
          now: DateTime.now(), lastCookedLookup: lastCookedAt);

  /// Return all visible variants for a dish (respecting profile).
  List<Recipe> visibleVariantsFor(Dish dish) {
    final variants = dish.variantRecipeIds.map((id) => corpus.recipeIndex[id]).whereType<Recipe>().toList();
    return variants.where((r) => matchRecipe(r, _profile, corpus.ontology).visible).toList();
  }

  /// Pick the default best variant for a dish.
  Recipe? bestVariantFor(Dish dish) {
    final variants = dish.variantRecipeIds.map((id) => corpus.recipeIndex[id]).whereType<Recipe>().toList();
    return pickBestVariant(variants, _profile, corpus.ontology,
        now: DateTime.now(), lastCookedLookup: lastCookedAt);
  }

  // ---- Backup/restore ----
  Map<String, dynamic> toBackupJson() => {
        'schema_version': 1,
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'profile': _profile.toJson(),
        'saved': savedRecipeIds,
        'meal_plan': mealPlan,
        'history': history
            .map((e) => {'recipe_id': e.recipeId, 'cooked_at': e.cookedAt.toIso8601String()})
            .toList(),
        'content_requests': contentRequests,
      };

  Future<void> restoreFromBackup(Map<String, dynamic> backup, {required bool replace}) async {
    if (replace) {
      await _cookbookBox.clear();
      await _mealPlanBox.clear();
      await _historyBox.clear();
      await _requestsBox.clear();
    }
    final profileJson = backup['profile'];
    if (profileJson is Map) {
      _profile = Profile.fromJson(Map<String, dynamic>.from(profileJson));
      prefs.setString('profile', json.encode(_profile.toJson()));
    }
    for (final id in (backup['saved'] as List? ?? const [])) {
      _cookbookBox.put(id.toString(), DateTime.now().toIso8601String());
    }
    final mp = backup['meal_plan'];
    if (mp is Map) {
      mp.forEach((weekKey, slots) {
        if (slots is Map) _mealPlanBox.put(weekKey.toString(), json.encode(slots));
      });
    }
    final hist = backup['history'];
    if (hist is List) {
      _historyBox.put('entries', json.encode(hist));
    }
    final cr = backup['content_requests'];
    if (cr is List) {
      _requestsBox.put('entries', json.encode(cr));
    }
    notifyListeners();
  }
}
