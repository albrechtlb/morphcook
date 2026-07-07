import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' hide Padding, State;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MorphCookApp());
}

class MorphCookApp extends StatefulWidget {
  const MorphCookApp({super.key});

  @override
  State<MorphCookApp> createState() => _MorphCookAppState();
}

class _MorphCookAppState extends State<MorphCookApp> {
  final app = AppState();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    app.load().then((_) => setState(() => ready = true));
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      app: app,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MorphCook',
        theme: MorphTheme.light,
        home: ready ? const RootScreen() : const LoadingScreen(),
      ),
    );
  }
}

/// Exposes [AppState] to the widget tree and rebuilds every dependent whenever
/// the [AppState] notifies. Uses [InheritedNotifier] so that dependents are
/// rebuilt by element (dependency) rather than by widget identity — this is
/// what keeps `const` screens (e.g. RootScreen) updating on state changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState app, required super.child, super.key})
    : super(notifier: app);

  static AppState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  }
}

class AppState extends ChangeNotifier {
  static const stateKey = 'morphcook.local_state.v1';

  Corpus corpus = Corpus.empty();
  Profile profile = Profile.defaultProfile();
  final Set<String> saved = {'doener-vegan-easy-600'};
  final Map<String, String> mealPlan = {};
  final List<String> shoppingRecipeIds = [];
  final List<HistoryEntry> history = [];
  final List<String> contentRequests = [];
  final Map<String, CookProgress> cookProgress = {};
  int tab = 0;

  Future<void> load() async {
    corpus = await Corpus.load();
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(stateKey);
    if (encoded != null) {
      BackupService.apply(
        this,
        jsonDecode(encoded) as Map<String, dynamic>,
        merge: false,
      );
    }
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(stateKey, jsonEncode(BackupService.toJson(this)));
  }

  void changed() {
    unawaited(persist());
    notifyListeners();
  }

  String get lang => profile.lang;

  void completeOnboarding(Profile next) {
    profile = next.copyWith(onboarded: true);
    changed();
  }

  void updateProfile(Profile next) {
    profile = next;
    changed();
  }

  void setTab(int index) {
    tab = index;
    changed();
  }

  void toggleSaved(String recipeId) {
    saved.contains(recipeId) ? saved.remove(recipeId) : saved.add(recipeId);
    changed();
  }

  void addToShopping(String recipeId) {
    shoppingRecipeIds.add(recipeId);
    changed();
  }

  void clearShopping() {
    shoppingRecipeIds.clear();
    changed();
  }

  void assignMeal(String slot, String recipeId) {
    mealPlan[slot] = recipeId;
    changed();
  }

  void moveMeal(String from, String to) {
    final recipe = mealPlan.remove(from);
    if (recipe != null) mealPlan[to] = recipe;
    changed();
  }

  void exportMealPlanToShopping() {
    shoppingRecipeIds.addAll(mealPlan.values);
    changed();
  }

  void saveCookProgress(CookProgress progress) {
    cookProgress[progress.recipeId] = progress;
    changed();
  }

  void clearCookProgress(String recipeId) {
    cookProgress.remove(recipeId);
    changed();
  }

  void cooked(String recipeId) {
    history.add(HistoryEntry(recipeId, DateTime.now()));
    cookProgress.remove(recipeId);
    changed();
  }

  String exportBackup({String? password}) {
    final payload = BackupService.toJson(this);
    if (password != null && password.isNotEmpty) {
      return BackupService.encryptForDisplay(payload, password);
    }
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Uint8List exportGzipBackup() {
    return Uint8List.fromList(
      gzip.encode(utf8.encode(jsonEncode(BackupService.toJson(this)))),
    );
  }

  void restoreBackup(String text, {String? password, bool merge = true}) {
    final data = BackupService.parseText(text, password: password);
    BackupService.apply(this, data, merge: merge);
    changed();
  }

  Future<void> shareBackupFiles({String? password}) async {
    final dir = await getTemporaryDirectory();
    final jsonFile = File('${dir.path}/morphcook-backup.json');
    final gzipFile = File('${dir.path}/morphcook-backup.json.gz');
    await jsonFile.writeAsString(exportBackup(password: password));
    await gzipFile.writeAsBytes(exportGzipBackup());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(jsonFile.path), XFile(gzipFile.path)],
        text: 'MorphCook backup',
      ),
    );
  }
}

class Corpus {
  Corpus({
    required this.dishes,
    required this.recipes,
    required this.ontology,
    required this.ingredients,
    required this.guides,
    required this.faqs,
  });

  final List<Dish> dishes;
  final List<Recipe> recipes;
  final Ontology ontology;
  final List<IngredientNode> ingredients;
  final List<IngredientGuide> guides;
  final List<FaqEntry> faqs;

  static Corpus empty() => Corpus(
    dishes: [],
    recipes: [],
    ontology: Ontology({}, [], [], []),
    ingredients: [],
    guides: [],
    faqs: [],
  );

  static Future<Corpus> load() async {
    final dishesJson = await _assetList('assets/dishes.json');
    final recipesJson = <Map<String, dynamic>>[];
    for (final path in [
      'assets/core-recipes.json',
      'assets/extended-recipes.json',
      'assets/cuisine-italian.json',
      'assets/cuisine-asian.json',
      'assets/cuisine-middle-eastern.json',
    ]) {
      recipesJson.addAll(await _assetList(path));
    }
    final unique = <String, Recipe>{};
    for (final json in recipesJson) {
      final recipe = Recipe.fromJson(json);
      unique[recipe.id] = recipe;
    }
    return Corpus(
      dishes: dishesJson.map(Dish.fromJson).toList(),
      recipes: unique.values.toList(),
      ontology: Ontology.fromJson(await _assetMap('assets/ontology.json')),
      ingredients: (await _assetList(
        'assets/ingredients.json',
      )).map(IngredientNode.fromJson).toList(),
      guides: (await _assetList(
        'assets/ingredient-guide.json',
      )).map(IngredientGuide.fromJson).toList(),
      faqs: (await _assetList(
        'assets/faqs.json',
      )).map(FaqEntry.fromJson).toList(),
    );
  }

  static Future<Map<String, dynamic>> _assetMap(String path) async {
    return jsonDecode(await rootBundle.loadString(path))
        as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> _assetList(String path) async {
    return (jsonDecode(await rootBundle.loadString(path)) as List)
        .cast<Map<String, dynamic>>();
  }

  Recipe recipe(String id) => recipes.firstWhere((recipe) => recipe.id == id);

  /// Safe lookup: returns `null` instead of throwing when [id] is unknown
  /// (e.g. a saved/meal-plan/backup id that is no longer in the corpus).
  Recipe? recipeOrNull(String id) {
    for (final recipe in recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  Dish dishForRecipe(String recipeId) {
    return dishes.firstWhere((dish) => dish.recipeIds.contains(recipeId));
  }

  /// Safe variant of [dishForRecipe] that returns `null` for unknown ids.
  Dish? dishForRecipeOrNull(String recipeId) {
    for (final dish in dishes) {
      if (dish.recipeIds.contains(recipeId)) return dish;
    }
    return null;
  }

  IngredientGuide? guide(String id) {
    for (final guide in guides) {
      if (guide.id == id) return guide;
    }
    return null;
  }
}

class L10n {
  static String pick(Map<String, String> text, String lang) =>
      text[lang] ?? text['en'] ?? text.values.first;
}

class Dish {
  Dish({
    required this.id,
    required this.name,
    required this.hero,
    required this.caption,
    required this.stripe,
    required this.recipeIds,
    required this.cuisineTags,
  });
  final String id;
  final Map<String, String> name;
  final Map<String, String> hero;
  final Map<String, String> caption;
  final Color stripe;
  final List<String> recipeIds;
  final List<String> cuisineTags;

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
    id: json['id'],
    name: _localized(json['name']),
    hero: _localized(json['hero']),
    caption: _localized(json['caption']),
    stripe: Color(
      int.parse((json['stripe_color'] as String).replaceFirst('#', '0xff')),
    ),
    recipeIds: (json['recipe_ids'] as List).cast<String>(),
    cuisineTags: (json['cuisine_tags'] as List).cast<String>(),
  );
}

class Recipe {
  Recipe({
    required this.id,
    required this.dishId,
    required this.title,
    required this.diet,
    required this.effort,
    required this.calorieLevel,
    required this.calories,
    required this.timeMinutes,
    required this.servings,
    required this.contains,
    required this.attributes,
    required this.tags,
    required this.mealTypes,
    required this.ingredients,
    required this.steps,
    required this.macros,
  });

  final String id;
  final String dishId;
  final Map<String, String> title;
  final String diet;
  final String effort;
  final String calorieLevel;
  final int calories;
  final int timeMinutes;
  final int servings;
  final Set<String> contains;
  final Set<String> attributes;
  final List<String> tags;
  final List<String> mealTypes;
  final List<RecipeIngredient> ingredients;
  final List<CookStep> steps;
  final Map<String, num> macros;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
    id: json['id'],
    dishId: json['dish_id'],
    title: _localized(json['title']),
    diet: json['diet'],
    effort: json['effort'],
    calorieLevel: json['calorie_level'],
    calories: json['calories_per_serving'],
    timeMinutes: json['time_minutes'],
    servings: json['servings'],
    contains: (json['contains'] as List).cast<String>().toSet(),
    attributes: (json['attributes'] as List).cast<String>().toSet(),
    tags: (json['tags'] as List).cast<String>(),
    mealTypes: (json['meal_types'] as List).cast<String>(),
    ingredients: (json['ingredients'] as List)
        .cast<Map<String, dynamic>>()
        .map(RecipeIngredient.fromJson)
        .toList(),
    steps: (json['steps'] as List)
        .cast<Map<String, dynamic>>()
        .map(CookStep.fromJson)
        .toList(),
    macros: (json['macros'] as Map).cast<String, num>(),
  );

  Set<String> get ingredientIds =>
      ingredients.map((ingredient) => ingredient.id).toSet();
}

class RecipeIngredient {
  RecipeIngredient({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.aisle,
  });
  final String id;
  final Map<String, String> name;
  final double amount;
  final String unit;
  final String aisle;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        id: json['id'],
        name: _localized(json['name']),
        amount: (json['amount'] as num).toDouble(),
        unit: json['unit'],
        aisle: json['aisle'],
      );
}

class CookStep {
  CookStep({required this.text, required this.timerSeconds});
  final Map<String, String> text;
  final int timerSeconds;

  factory CookStep.fromJson(Map<String, dynamic> json) => CookStep(
    text: _localized(json['text']),
    timerSeconds: json['timer_seconds'] ?? 0,
  );
}

class Profile {
  Profile({
    required this.name,
    required this.lang,
    required this.avoidFlags,
    required this.avoidIngredients,
    required this.requiredAttributes,
    required this.maxTimeMinutes,
    required this.calorieTarget,
    required this.preferredEffort,
    required this.showVariantTags,
    required this.visualAlertEnabled,
    required this.quickNextTapEnabled,
    required this.reduceMotion,
    required this.onboarded,
  });

  final String name;
  final String lang;
  final Set<String> avoidFlags;
  final Set<String> avoidIngredients;
  final Set<String> requiredAttributes;
  final int maxTimeMinutes;
  final int calorieTarget;
  final String preferredEffort;
  final bool showVariantTags;
  final bool visualAlertEnabled;
  final bool quickNextTapEnabled;
  final bool? reduceMotion;
  final bool onboarded;

  static Profile defaultProfile() => Profile(
    name: 'Mira',
    lang: 'en',
    avoidFlags: {'pork'},
    avoidIngredients: {},
    requiredAttributes: {},
    maxTimeMinutes: 45,
    calorieTarget: 600,
    preferredEffort: 'easy',
    showVariantTags: true,
    visualAlertEnabled: true,
    quickNextTapEnabled: false,
    reduceMotion: null,
    onboarded: false,
  );

  Profile copyWith({
    String? name,
    String? lang,
    Set<String>? avoidFlags,
    Set<String>? avoidIngredients,
    Set<String>? requiredAttributes,
    int? maxTimeMinutes,
    int? calorieTarget,
    String? preferredEffort,
    bool? showVariantTags,
    bool? visualAlertEnabled,
    bool? quickNextTapEnabled,
    bool? reduceMotion,
    bool? onboarded,
  }) {
    return Profile(
      name: name ?? this.name,
      lang: lang ?? this.lang,
      avoidFlags: avoidFlags ?? this.avoidFlags,
      avoidIngredients: avoidIngredients ?? this.avoidIngredients,
      requiredAttributes: requiredAttributes ?? this.requiredAttributes,
      maxTimeMinutes: maxTimeMinutes ?? this.maxTimeMinutes,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      preferredEffort: preferredEffort ?? this.preferredEffort,
      showVariantTags: showVariantTags ?? this.showVariantTags,
      visualAlertEnabled: visualAlertEnabled ?? this.visualAlertEnabled,
      quickNextTapEnabled: quickNextTapEnabled ?? this.quickNextTapEnabled,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'lang': lang,
    'avoid_flags': avoidFlags.toList(),
    'avoid_ingredients': avoidIngredients.toList(),
    'required_attributes': requiredAttributes.toList(),
    'max_time_minutes': maxTimeMinutes,
    'calorie_target': calorieTarget,
    'preferred_effort': preferredEffort,
    'show_variant_tags': showVariantTags,
    'visualAlertEnabled': visualAlertEnabled,
    'quickNextTapEnabled': quickNextTapEnabled,
    'reduceMotion': reduceMotion,
    'onboarded': onboarded,
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'] ?? 'cook',
    lang: json['lang'] ?? 'en',
    avoidFlags: ((json['avoid_flags'] ?? []) as List).cast<String>().toSet(),
    avoidIngredients: ((json['avoid_ingredients'] ?? []) as List)
        .cast<String>()
        .toSet(),
    requiredAttributes: ((json['required_attributes'] ?? []) as List)
        .cast<String>()
        .toSet(),
    maxTimeMinutes: json['max_time_minutes'] ?? 45,
    calorieTarget: json['calorie_target'] ?? 600,
    preferredEffort: json['preferred_effort'] ?? 'easy',
    showVariantTags: json['show_variant_tags'] ?? true,
    visualAlertEnabled: json['visualAlertEnabled'] ?? true,
    quickNextTapEnabled: json['quickNextTapEnabled'] ?? false,
    reduceMotion: json['reduceMotion'],
    onboarded: json['onboarded'] ?? true,
  );
}

class Ontology {
  Ontology(
    this.compoundAvoidFlags,
    this.containsFlags,
    this.efforts,
    this.calorieLevels,
  );
  final Map<String, Set<String>> compoundAvoidFlags;
  final List<String> containsFlags;
  final List<String> efforts;
  final List<String> calorieLevels;

  factory Ontology.fromJson(Map<String, dynamic> json) => Ontology(
    (json['compound_avoid_flags'] as Map).map(
      (key, value) =>
          MapEntry(key as String, (value as List).cast<String>().toSet()),
    ),
    (json['contains_flags'] as List).cast<String>(),
    (json['efforts'] as List).cast<String>(),
    (json['calorie_levels'] as List).cast<String>(),
  );
}

class IngredientNode {
  IngredientNode({
    required this.id,
    required this.name,
    required this.children,
  });
  final String id;
  final Map<String, String> name;
  final List<IngredientNode> children;

  factory IngredientNode.fromJson(Map<String, dynamic> json) => IngredientNode(
    id: json['id'],
    name: _localized(json['name']),
    children: ((json['children'] ?? []) as List)
        .cast<Map<String, dynamic>>()
        .map(IngredientNode.fromJson)
        .toList(),
  );

  List<IngredientNode> flatten() => [
    this,
    ...children.expand((child) => child.flatten()),
  ];
}

class IngredientGuide {
  IngredientGuide({
    required this.id,
    required this.title,
    required this.description,
    required this.usage,
    required this.storage,
    required this.whereToFind,
  });
  final String id;
  final Map<String, String> title;
  final Map<String, String> description;
  final Map<String, String> usage;
  final Map<String, String> storage;
  final Map<String, String> whereToFind;

  factory IngredientGuide.fromJson(Map<String, dynamic> json) =>
      IngredientGuide(
        id: json['id'],
        title: _localized(json['title']),
        description: _localized(json['description']),
        usage: _localized(json['usage']),
        storage: _localized(json['storage']),
        whereToFind: _localized(json['where_to_find']),
      );
}

class FaqEntry {
  FaqEntry({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.link,
  });
  final String id;
  final String category;
  final Map<String, String> question;
  final Map<String, String> answer;
  final String link;

  factory FaqEntry.fromJson(Map<String, dynamic> json) => FaqEntry(
    id: json['id'],
    category: json['category'],
    question: _localized(json['question']),
    answer: _localized(json['answer']),
    link: json['link'] ?? '',
  );
}

class HistoryEntry {
  HistoryEntry(this.recipeId, this.cookedAt);
  final String recipeId;
  final DateTime cookedAt;

  Map<String, dynamic> toJson() => {
    'recipe_id': recipeId,
    'cooked_at': cookedAt.toIso8601String(),
  };
  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      HistoryEntry(json['recipe_id'], DateTime.parse(json['cooked_at']));
}

Map<String, String> _localized(Object? value) =>
    (value as Map).cast<String, String>();

class CookProgress {
  CookProgress({
    required this.recipeId,
    required this.stepIndex,
    required this.remainingSeconds,
    required this.servingsScale,
  });
  final String recipeId;
  final int stepIndex;
  final int remainingSeconds;
  final double servingsScale;

  Map<String, dynamic> toJson() => {
    'recipe_id': recipeId,
    'step_index': stepIndex,
    'remaining_seconds': remainingSeconds,
    'servings_scale': servingsScale,
  };

  factory CookProgress.fromJson(Map<String, dynamic> json) => CookProgress(
    recipeId: json['recipe_id'],
    stepIndex: json['step_index'] ?? 0,
    remainingSeconds: json['remaining_seconds'] ?? 0,
    servingsScale: (json['servings_scale'] ?? 1).toDouble(),
  );
}

class PaginationController<T> extends ChangeNotifier {
  PaginationController({
    required this.pageSize,
    required this.prefetchThreshold,
    this.maxRendered = 50,
  });
  final int pageSize;
  final int prefetchThreshold;
  final int maxRendered;
  int loaded = 0;
  bool loading = false;
  Object? error;

  void reset() {
    loaded = 0;
    loading = false;
    error = null;
    notifyListeners();
  }

  void refresh(int total) {
    loaded = min(pageSize, min(total, maxRendered));
    loading = false;
    error = null;
    notifyListeners();
  }

  void loadMore(int total) {
    if (loading || loaded >= total || loaded >= maxRendered) return;
    loading = true;
    notifyListeners();
    loaded = min(maxRendered, min(total, loaded + pageSize));
    loading = false;
    notifyListeners();
  }

  bool shouldLoadMore(int index) => index >= loaded - prefetchThreshold;
}

class Matching {
  static const tolerance = 160;

  static Set<String> expandedAvoidFlags(Profile profile, Ontology ontology) {
    final flags = <String>{};
    for (final flag in profile.avoidFlags) {
      flags.addAll(ontology.compoundAvoidFlags[flag] ?? {flag});
    }
    return flags;
  }

  static bool visible(
    Recipe recipe,
    Profile profile,
    Ontology ontology, {
    bool calorieOverride = false,
  }) {
    final avoid = expandedAvoidFlags(profile, ontology);
    return recipe.contains.intersection(avoid).isEmpty &&
        profile.avoidIngredients.intersection(recipe.ingredientIds).isEmpty &&
        recipe.attributes.containsAll(profile.requiredAttributes) &&
        recipe.timeMinutes <= profile.maxTimeMinutes &&
        (calorieOverride ||
            (recipe.calories - profile.calorieTarget).abs() <= tolerance);
  }

  static int score(
    Recipe recipe,
    Profile profile, {
    DateTime? now,
    DateTime? lastCooked,
  }) {
    var score = 0;
    score +=
        profile.requiredAttributes.intersection(recipe.attributes).length *
        1000;
    if (recipe.effort == profile.preferredEffort) score += 280;
    score += max(
      0,
      220 - (recipe.timeMinutes - profile.maxTimeMinutes).abs() * 5,
    );
    score += max(0, 180 - (recipe.calories - profile.calorieTarget).abs());
    final time = now ?? DateTime.now();
    if (time.hour >= 5 &&
        time.hour < 11 &&
        recipe.mealTypes.contains('breakfast')) {
      score += 200;
    }
    if (time.hour >= 17 &&
        time.hour < 21 &&
        recipe.mealTypes.contains('dinner')) {
      score += 90;
    }
    if ((time.weekday == DateTime.saturday ||
            time.weekday == DateTime.sunday) &&
        recipe.effort != 'easy') {
      score += 90;
    }
    if (lastCooked != null && time.difference(lastCooked).inDays >= 30) {
      score += 50;
    }
    return score;
  }

  static Recipe bestForDish(
    Dish dish,
    Corpus corpus,
    Profile profile, {
    bool calorieOverride = false,
  }) {
    final variants = dish.recipeIds
        .map(corpus.recipe)
        .where(
          (recipe) => visible(
            recipe,
            profile,
            corpus.ontology,
            calorieOverride: calorieOverride,
          ),
        )
        .toList();
    final candidates = variants.isEmpty
        ? dish.recipeIds.map(corpus.recipe).toList()
        : variants;
    candidates.sort((a, b) => score(b, profile).compareTo(score(a, profile)));
    return candidates.first;
  }

  static Recipe? variantFor(
    Dish dish,
    Corpus corpus,
    String diet,
    String effort,
    String calories,
  ) {
    for (final recipe in dish.recipeIds.map(corpus.recipe)) {
      if (recipe.diet == diet &&
          recipe.effort == effort &&
          recipe.calorieLevel == calories) {
        return recipe;
      }
    }
    return null;
  }

  static bool conflictsWithProfile(
    Recipe recipe,
    Profile profile,
    Ontology ontology,
  ) {
    return !visible(recipe, profile, ontology);
  }
}

class SearchEngine {
  static List<Recipe> query(
    Corpus corpus,
    Profile profile,
    String text,
    Set<String> tags,
  ) {
    final q = text.toLowerCase().trim();
    final results = corpus.recipes.where((recipe) {
      if (!Matching.visible(recipe, profile, corpus.ontology)) return false;
      final haystack = [
        ...recipe.title.values,
        ...recipe.tags,
        recipe.diet,
        recipe.effort,
        ...recipe.ingredients.expand((ingredient) => ingredient.name.values),
      ].join(' ').toLowerCase();
      final textOk = q.isEmpty || haystack.contains(q);
      final tagsOk =
          tags.isEmpty ||
          tags.every(
            (tag) =>
                recipe.tags.contains(tag) ||
                recipe.diet == tag ||
                recipe.effort == tag,
          );
      return textOk && tagsOk;
    }).toList();
    results.sort(
      (a, b) =>
          Matching.score(b, profile).compareTo(Matching.score(a, profile)),
    );
    return results.take(50).toList();
  }
}

class Shopping {
  static Map<String, List<ShoppingLine>> aggregate(Iterable<Recipe> recipes) {
    final lines = <String, ShoppingLine>{};
    for (final recipe in recipes) {
      for (final ingredient in recipe.ingredients) {
        final normalized = Units.normalize(ingredient.amount, ingredient.unit);
        final key = '${ingredient.id}:${normalized.unit}';
        final current = lines[key];
        if (current == null) {
          lines[key] = ShoppingLine(
            ingredient.id,
            ingredient.name,
            normalized.amount,
            normalized.unit,
            ingredient.aisle,
            1,
          );
        } else {
          lines[key] = current.copyWith(
            amount: current.amount + normalized.amount,
            frequency: current.frequency + 1,
          );
        }
      }
    }
    final grouped = <String, List<ShoppingLine>>{};
    for (final line in lines.values) {
      grouped.putIfAbsent(line.aisle, () => []).add(line);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.name['en']!.compareTo(b.name['en']!));
    }
    return grouped;
  }
}

class Units {
  static UnitAmount normalize(double amount, String unit) {
    if (unit == 'tbsp') return UnitAmount(amount * 15, 'ml');
    if (unit == 'tsp') return UnitAmount(amount * 5, 'ml');
    return UnitAmount(amount, unit);
  }
}

class UnitAmount {
  UnitAmount(this.amount, this.unit);
  final double amount;
  final String unit;
}

class ShoppingLine {
  ShoppingLine(
    this.id,
    this.name,
    this.amount,
    this.unit,
    this.aisle,
    this.frequency,
  );
  final String id;
  final Map<String, String> name;
  final double amount;
  final String unit;
  final String aisle;
  final int frequency;

  ShoppingLine copyWith({double? amount, int? frequency}) => ShoppingLine(
    id,
    name,
    amount ?? this.amount,
    unit,
    aisle,
    frequency ?? this.frequency,
  );
}

class BackupService {
  static const magic = 'ENC';
  static const saltLength = 16;
  static const ivLength = 12;
  static const keyLength = 32;
  static const iterations = 10000;

  static Map<String, dynamic> toJson(AppState app) => {
    'schema_version': 1,
    'exported_at': DateTime.now().toUtc().toIso8601String(),
    'profile': app.profile.toJson(),
    'saved': app.saved.toList(),
    'meal_plan': {'2026-W16': app.mealPlan},
    'history': app.history.map((entry) => entry.toJson()).toList(),
    'content_requests': app.contentRequests,
    'cook_progress': app.cookProgress.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };

  static String encryptForDisplay(
    Map<String, dynamic> payload,
    String password,
  ) {
    return '$magic${base64Encode(encryptBytes(utf8.encode(jsonEncode(payload)), password).sublist(3))}';
  }

  static Uint8List encryptBytes(List<int> plaintext, String password) {
    final salt = _randomBytes(saltLength);
    final iv = _randomBytes(ivLength);
    final key = _deriveKey(password, salt);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    final encrypted = cipher.process(Uint8List.fromList(plaintext));
    return Uint8List.fromList([
      ...magic.codeUnits,
      ...salt,
      ...iv,
      ...encrypted,
    ]);
  }

  static Map<String, dynamic> parseText(String text, {String? password}) {
    final source = text.trim();
    if (source.startsWith(magic)) {
      if (password == null || password.isEmpty) {
        throw const FormatException('Incorrect password. Please try again.');
      }
      final bytes = Uint8List.fromList([
        ...magic.codeUnits,
        ...base64Decode(source.substring(3)),
      ]);
      return _parseJsonBytes(decryptBytes(bytes, password));
    }
    return _parseJsonBytes(utf8.encode(source));
  }

  static Map<String, dynamic> parseBytes(Uint8List bytes, {String? password}) {
    if (_hasMagic(bytes, magic.codeUnits)) {
      if (password == null || password.isEmpty) {
        throw const FormatException('Incorrect password. Please try again.');
      }
      return _parseJsonBytes(decryptBytes(bytes, password));
    }
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      return _parseJsonBytes(gzip.decode(bytes));
    }
    return _parseJsonBytes(bytes);
  }

  static Uint8List decryptBytes(Uint8List bytes, String password) {
    try {
      if (!_hasMagic(bytes, magic.codeUnits)) {
        throw const FormatException(
          'This file is not a valid MorphCook backup.',
        );
      }
      final saltStart = magic.length;
      final ivStart = saltStart + saltLength;
      final cipherStart = ivStart + ivLength;
      final salt = bytes.sublist(saltStart, ivStart);
      final iv = bytes.sublist(ivStart, cipherStart);
      final encrypted = bytes.sublist(cipherStart);
      final key = _deriveKey(password, salt);
      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
      return cipher.process(encrypted);
    } on InvalidCipherTextException {
      throw const FormatException('Incorrect password. Please try again.');
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
        'Backup file is corrupted and cannot be restored.',
      );
    }
  }

  static Map<String, dynamic> _parseJsonBytes(List<int> bytes) {
    final data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (data['schema_version'] != 1) {
      throw const FormatException('This file is not a valid MorphCook backup.');
    }
    return data;
  }

  static Uint8List _deriveKey(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, keyLength));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static bool _hasMagic(List<int> bytes, List<int> magicBytes) {
    if (bytes.length < magicBytes.length) return false;
    for (var i = 0; i < magicBytes.length; i++) {
      if (bytes[i] != magicBytes[i]) return false;
    }
    return true;
  }

  static void apply(
    AppState app,
    Map<String, dynamic> data, {
    required bool merge,
  }) {
    if (!merge) {
      app.saved.clear();
      app.mealPlan.clear();
      app.history.clear();
      app.contentRequests.clear();
      app.cookProgress.clear();
    }
    app.profile = Profile.fromJson(
      (data['profile'] ?? {}) as Map<String, dynamic>,
    );
    app.saved.addAll(((data['saved'] ?? []) as List).cast<String>());
    final plans = data['meal_plan'];
    if (plans is Map && plans.isNotEmpty) {
      final first = plans.values.first;
      if (first is Map) app.mealPlan.addAll(first.cast<String, String>());
    }
    app.history.addAll(
      ((data['history'] ?? []) as List).cast<Map<String, dynamic>>().map(
        HistoryEntry.fromJson,
      ),
    );
    app.contentRequests.addAll(
      ((data['content_requests'] ?? []) as List).cast<String>(),
    );
    final progress = data['cook_progress'];
    if (progress is Map) {
      app.cookProgress.addAll(
        progress.map(
          (key, value) => MapEntry(
            key as String,
            CookProgress.fromJson((value as Map).cast<String, dynamic>()),
          ),
        ),
      );
    }
  }
}

class MorphTheme {
  static const ink = Color(0xff332820);
  static const paper = Color(0xfff3eadb);
  static const paperDark = Color(0xffe6d7bf);
  static const coral = Color(0xffd98673);
  static const teal = Color(0xff5f9d95);
  static const sage = Color(0xffa7ad85);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: coral,
      scaffoldBackgroundColor: paper,
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            fontFamily: 'Playfair Display',
            bodyColor: ink,
            displayColor: ink,
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontSize: 42,
              height: 0.95,
              color: ink,
            ),
            headlineMedium: const TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontSize: 28,
              color: ink,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'Playfair Display',
              fontStyle: FontStyle.italic,
              fontSize: 23,
              color: ink,
            ),
            bodyMedium: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 15,
              height: 1.38,
              color: ink,
            ),
            labelMedium: const TextStyle(
              fontFamily: 'JetBrains Mono',
              letterSpacing: 1.2,
              fontSize: 11,
              color: ink,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xffeadcc8),
        selectedColor: teal.withValues(alpha: .28),
        labelStyle: const TextStyle(color: ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: paper,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Paper(child: Center(child: Text('MorphCook')));
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    if (!app.profile.onboarded) return const OnboardingScreen();
    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      const CookbookScreen(),
      const MealPlanScreen(),
      const SettingsScreen(),
    ];
    return Paper(
      child: Scaffold(
        body: SafeArea(child: screens[app.tab]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: app.tab,
          backgroundColor: MorphTheme.paperDark.withValues(alpha: .92),
          onDestinationSelected: app.setTab,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'home',
            ),
            NavigationDestination(icon: Icon(Icons.search), label: 'search'),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'plan',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: 'settings',
            ),
          ],
        ),
      ),
    );
  }
}

class Paper extends StatelessWidget {
  const Paper({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MorphTheme.paper,
      child: CustomPaint(painter: PaperPainter(), child: child),
    );
  }
}

class PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: .025);
    for (var y = 0.0; y < size.height; y += 7) {
      for (var x = (y % 14); x < size.width; x += 13) {
        canvas.drawCircle(Offset(x, y), .55, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  var step = 0;
  late Profile profile = AppScope.of(context).profile;
  final nameController = TextEditingController(text: 'Mira');

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pages = [language(), name(), diet(), targets(), confirm(app)];
    return Paper(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Mono('onboarding ${step + 1}/5'),
                const SizedBox(height: 20),
                Expanded(child: pages[step]),
                Row(
                  children: [
                    if (step > 0)
                      TextButton(
                        onPressed: () => setState(() => step--),
                        child: const Text('back'),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => step == 4
                          ? app.completeOnboarding(
                              profile.copyWith(name: nameController.text),
                            )
                          : setState(() => step++),
                      child: Text(step == 4 ? 'open cookbook' : 'next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget language() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Display('choose your kitchen language'),
      const SizedBox(height: 22),
      Wrap(
        spacing: 10,
        children: [
          ChoiceChip(
            label: const Text('English'),
            selected: profile.lang == 'en',
            onSelected: (_) =>
                setState(() => profile = profile.copyWith(lang: 'en')),
          ),
          ChoiceChip(
            label: const Text('Deutsch'),
            selected: profile.lang == 'de',
            onSelected: (_) =>
                setState(() => profile = profile.copyWith(lang: 'de')),
          ),
        ],
      ),
    ],
  );

  Widget name() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Display('what should the cookbook call you?'),
      const SizedBox(height: 20),
      TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: 'name',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );

  Widget diet() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Display('diet & gentle no-thank-yous'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'vegan',
            'vegetarian',
            'halal',
            'kosher',
            'pork',
            'dairy',
            'tree-nuts',
            'shellfish',
            'gluten',
          ].map(flagChip).toList(),
        ),
        const SizedBox(height: 18),
        const Text('specific avoidance'),
        Wrap(
          spacing: 8,
          children: [
            'cilantro',
            'apples',
            'bell-pepper',
            'peanuts',
          ].map(ingredientChip).toList(),
        ),
      ],
    ),
  );

  Widget targets() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Display('today-sized recipes'),
      Slider(
        value: profile.calorieTarget.toDouble(),
        min: 400,
        max: 800,
        divisions: 4,
        label: '${profile.calorieTarget} kcal',
        onChanged: (v) => setState(
          () => profile = profile.copyWith(calorieTarget: v.round()),
        ),
      ),
      Text('calorie target: ${profile.calorieTarget}'),
      Slider(
        value: profile.maxTimeMinutes.toDouble(),
        min: 15,
        max: 75,
        divisions: 4,
        label: '${profile.maxTimeMinutes} min',
        onChanged: (v) => setState(
          () => profile = profile.copyWith(maxTimeMinutes: v.round()),
        ),
      ),
      Text('time budget: ${profile.maxTimeMinutes} min'),
      Wrap(
        spacing: 8,
        children: ['easy', 'medium', 'hard']
            .map(
              (effort) => ChoiceChip(
                label: Text(effort),
                selected: profile.preferredEffort == effort,
                onSelected: (_) => setState(
                  () => profile = profile.copyWith(preferredEffort: effort),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget confirm(AppState app) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Display('your recipes stay yours'),
      const SizedBox(height: 16),
      const Text(
        'Offline only. No account. No telemetry. The bundled cookbook is filtered by your profile, but variants outside it remain visible when you choose them.',
      ),
      const SizedBox(height: 16),
      Polaroid(
        dish: app.corpus.dishes.first,
        caption: 'striped placeholders forever',
        child: const SizedBox(height: 130),
      ),
    ],
  );

  Widget flagChip(String flag) => FilterChip(
    label: Text(flag),
    selected: profile.avoidFlags.contains(flag),
    onSelected: (_) {
      final next = {...profile.avoidFlags};
      next.contains(flag) ? next.remove(flag) : next.add(flag);
      setState(() => profile = profile.copyWith(avoidFlags: next));
    },
  );

  Widget ingredientChip(String id) => FilterChip(
    label: Text(id),
    selected: profile.avoidIngredients.contains(id),
    onSelected: (_) {
      final next = {...profile.avoidIngredients};
      next.contains(id) ? next.remove(id) : next.add(id);
      setState(() => profile = profile.copyWith(avoidIngredients: next));
    },
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final dishes = app.corpus.dishes;
    final featured = dishes.first;
    final lang = app.lang;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Mono('MORPHCOOK EVENING EDITION'),
        const SizedBox(height: 6),
        const Display('morphcook'),
        Text(
          'hello ${app.profile.name} — the same dishes, written for your body.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const DashedRule(),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DishDetailScreen(dish: featured)),
          ),
          child: Polaroid(
            dish: featured,
            caption: L10n.pick(featured.caption, lang),
            child: SizedBox(
              height: 180,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    L10n.pick(featured.name, lang),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SectionTitle('today\'s complete dishes'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dishes.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: .72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final dish = dishes[index];
            final recipe = Matching.bestForDish(dish, app.corpus, app.profile);
            return RecipeCard(
              dish: dish,
              recipe: recipe,
              rotation: index.isEven ? -.025 : .02,
            );
          },
        ),
      ],
    );
  }
}

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    required this.dish,
    required this.recipe,
    this.rotation = 0,
    super.key,
  });
  final Dish dish;
  final Recipe recipe;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Transform.rotate(
      angle: rotation,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DishDetailScreen(dish: dish, initialRecipe: recipe),
          ),
        ),
        child: Card(
          color: const Color(0xfffffbf2),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stripes(
                    color: dish.stripe,
                    caption: L10n.pick(dish.caption, app.lang),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  L10n.pick(dish.name, app.lang),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Mono('${recipe.timeMinutes} min · ${recipe.calories} kcal'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DishDetailScreen extends StatefulWidget {
  const DishDetailScreen({required this.dish, this.initialRecipe, super.key});
  final Dish dish;
  final Recipe? initialRecipe;

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  late Recipe selected;
  final expanded = <String>{};
  var calorieOverride = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selected =
        widget.initialRecipe ??
        Matching.bestForDish(
          widget.dish,
          AppScope.of(context).corpus,
          AppScope.of(context).profile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.lang;
    final conflicts = Matching.conflictsWithProfile(
      selected,
      app.profile,
      app.corpus.ontology,
    );
    return Paper(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () => app.toggleSaved(selected.id),
              icon: Icon(
                app.saved.contains(selected.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          children: [
            Mono('dish: ${widget.dish.id}'),
            Text(
              L10n.pick(widget.dish.name, lang),
              style: Theme.of(context).textTheme.displayLarge,
            ),
            Polaroid(
              dish: widget.dish,
              caption: L10n.pick(widget.dish.caption, lang),
              child: const SizedBox(height: 170),
            ),
            const SizedBox(height: 12),
            Text(L10n.pick(widget.dish.hero, lang)),
            SwitchListTile(
              value: calorieOverride,
              onChanged: (value) => setState(() => calorieOverride = value),
              title: const Text('show versions outside calorie target'),
              subtitle: Text(
                'target ${app.profile.calorieTarget} kcal ± ${Matching.tolerance}',
              ),
            ),
            DimensionSwitcher(
              label: 'diet',
              value: selected.diet,
              values: [
                'classic',
                'vegetarian',
                'vegan',
                'halal',
                'gluten-free',
              ],
              expanded: expanded.contains('diet'),
              muted: (value) => _muted(app, diet: value),
              disabled: (value) => _variant(diet: value) == null,
              note: 'not written yet — maybe soon',
              onHeader: () => _toggle('diet'),
              onPick: (value) => _pick(diet: value),
            ),
            DimensionSwitcher(
              label: 'effort',
              value: selected.effort,
              values: ['easy', 'medium', 'hard'],
              expanded: expanded.contains('effort'),
              muted: (value) => value != app.profile.preferredEffort,
              disabled: (value) => _variant(effort: value) == null,
              note: 'no version at that effort',
              onHeader: () => _toggle('effort'),
              onPick: (value) => _pick(effort: value),
            ),
            DimensionSwitcher(
              label: 'calorie level',
              value: selected.calorieLevel,
              values: ['400', '600', '800'],
              expanded: expanded.contains('calorie'),
              muted: (value) =>
                  (int.parse(value) - app.profile.calorieTarget).abs() >
                  Matching.tolerance,
              disabled: (value) => _variant(calorie: value) == null,
              note: 'no recipe at that calorie level',
              onHeader: () => _toggle('calorie'),
              onPick: (value) => _pick(calorie: value),
            ),
            if (conflicts)
              Note(
                'This version sits outside your profile, but it stays open. Your profile preselects; it never locks.',
              ),
            AnimatedSwitcher(
              duration: app.profile.reduceMotion == true
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              child: RecipeBody(key: ValueKey(selected.id), recipe: selected),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => app.addToShopping(selected.id),
                  icon: const Icon(Icons.shopping_basket_outlined),
                  label: const Text('add to shopping'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CookModeScreen(recipe: selected),
                    ),
                  ),
                  icon: const Icon(Icons.soup_kitchen_outlined),
                  label: const Text('cook mode'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Recipe? _variant({String? diet, String? effort, String? calorie}) =>
      Matching.variantFor(
        widget.dish,
        AppScope.of(context).corpus,
        diet ?? selected.diet,
        effort ?? selected.effort,
        calorie ?? selected.calorieLevel,
      );

  void _toggle(String id) {
    setState(
      () => expanded.contains(id) ? expanded.remove(id) : expanded.add(id),
    );
  }

  void _pick({String? diet, String? effort, String? calorie}) {
    final next = _variant(diet: diet, effort: effort, calorie: calorie);
    if (next != null) setState(() => selected = next);
  }

  bool _muted(AppState app, {String? diet}) {
    final recipe = _variant(diet: diet);
    return recipe != null &&
        Matching.conflictsWithProfile(recipe, app.profile, app.corpus.ontology);
  }
}

class DimensionSwitcher extends StatelessWidget {
  const DimensionSwitcher({
    required this.label,
    required this.value,
    required this.values,
    required this.expanded,
    required this.muted,
    required this.disabled,
    required this.note,
    required this.onHeader,
    required this.onPick,
    super.key,
  });
  final String label;
  final String value;
  final List<String> values;
  final bool expanded;
  final bool Function(String) muted;
  final bool Function(String) disabled;
  final String note;
  final VoidCallback onHeader;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onHeader,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Mono('— $label —'),
                const Expanded(child: DashedRule(horizontalPadding: 8)),
                Text(value),
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (expanded)
          Wrap(
            spacing: 8,
            children: values.map((item) {
              final off = disabled(item);
              return ChoiceChip(
                label: Text(off ? '$item · $note' : item),
                selected: value == item,
                onSelected: off ? null : (_) => onPick(item),
                labelStyle: TextStyle(
                  color: muted(item)
                      ? MorphTheme.ink.withValues(alpha: .48)
                      : MorphTheme.ink,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class RecipeBody extends StatelessWidget {
  const RecipeBody({required this.recipe, super.key});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('ingredients'),
        ...recipe.ingredients.map(
          (ingredient) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${_amount(ingredient.amount)} ${ingredient.unit} ${L10n.pick(ingredient.name, lang)}',
            ),
            trailing: app.corpus.guide(ingredient.id) == null
                ? null
                : TextButton(
                    onPressed: () =>
                        showGuide(context, app.corpus.guide(ingredient.id)!),
                    child: const Text('learn more'),
                  ),
          ),
        ),
        const SectionTitle('method'),
        ...recipe.steps.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Mono('${entry.key + 1}'.padLeft(2, '0')),
                const SizedBox(width: 12),
                Expanded(child: Text(L10n.pick(entry.value.text, lang))),
              ],
            ),
          ),
        ),
        const SectionTitle('macros'),
        Wrap(
          spacing: 8,
          children: recipe.macros.entries
              .map((entry) => Chip(label: Text('${entry.key}: ${entry.value}')))
              .toList(),
        ),
      ],
    );
  }
}

void showGuide(BuildContext context, IngredientGuide guide) {
  final lang = AppScope.of(context).lang;
  showModalBottomSheet(
    context: context,
    backgroundColor: MorphTheme.paper,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.pick(guide.title, lang),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(L10n.pick(guide.description, lang)),
          const SectionTitle('use'),
          Text(L10n.pick(guide.usage, lang)),
          const SectionTitle('storage'),
          Text(L10n.pick(guide.storage, lang)),
          const SectionTitle('where to find'),
          Text(L10n.pick(guide.whereToFind, lang)),
        ],
      ),
    ),
  );
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var query = '';
  final tags = <String>{};
  final pagination = PaginationController<Recipe>(
    pageSize: 20,
    prefetchThreshold: 10,
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final results = SearchEngine.query(app.corpus, app.profile, query, tags);
    if (pagination.loaded == 0 || pagination.loaded > results.length) {
      pagination.refresh(results.length);
    }
    if (query.isNotEmpty &&
        results.isEmpty &&
        !app.contentRequests.contains(query)) {
      app.contentRequests.add(query);
      app.changed();
    }
    final shown = min(results.length, pagination.loaded);
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: shown + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Display('search the pantry'),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'dish, tag, ingredient',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {
                  query = value;
                  pagination.reset();
                }),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children:
                    [
                          'vegan',
                          'classic',
                          'easy',
                          'medium',
                          'dinner',
                          'breakfast',
                        ]
                        .map(
                          (tag) => FilterChip(
                            label: Text(tag),
                            selected: tags.contains(tag),
                            onSelected: (_) => setState(() {
                              tags.contains(tag)
                                  ? tags.remove(tag)
                                  : tags.add(tag);
                              pagination.reset();
                            }),
                          ),
                        )
                        .toList(),
              ),
              const DashedRule(),
            ],
          );
        }
        final resultIndex = index - 1;
        if (resultIndex >= shown) {
          return results.length > shown
              ? Center(
                  child: TextButton(
                    onPressed: () =>
                        setState(() => pagination.loadMore(results.length)),
                    child: const Text('load more'),
                  ),
                )
              : const SizedBox.shrink();
        }
        if (pagination.shouldLoadMore(resultIndex)) {
          pagination.loadMore(results.length);
        }
        return RecipeRow(recipe: results[resultIndex]);
      },
    );
  }
}

class CookbookScreen extends StatelessWidget {
  const CookbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final recipes = app.saved
        .take(50)
        .map(app.corpus.recipeOrNull)
        .whereType<Recipe>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Display('your saved variants'),
        const Text(
          'saved as specific recipes — your döner, your alfredo, your effort level.',
        ),
        const DashedRule(),
        if (recipes.isEmpty) const Note('nothing saved yet'),
        ...recipes.map((recipe) => RecipeRow(recipe: recipe)),
      ],
    );
  }
}

class RecipeRow extends StatelessWidget {
  const RecipeRow({required this.recipe, super.key});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final dish = app.corpus.dishForRecipeOrNull(recipe.id);
    return Card(
      color: const Color(0xfffffbf2),
      child: ListTile(
        leading: SizedBox(
          width: 52,
          child: Stripes(color: dish?.stripe ?? MorphTheme.sage, caption: ''),
        ),
        title: Text(L10n.pick(recipe.title, app.lang)),
        subtitle: Text(
          '${recipe.diet} · ${recipe.effort} · ${recipe.calories} kcal · ${recipe.timeMinutes} min',
        ),
        trailing: IconButton(
          onPressed: () => app.toggleSaved(recipe.id),
          icon: Icon(
            app.saved.contains(recipe.id)
                ? Icons.bookmark
                : Icons.bookmark_border,
          ),
        ),
        onTap: dish == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DishDetailScreen(dish: dish, initialRecipe: recipe),
                ),
              ),
      ),
    );
  }
}

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final meals = ['breakfast', 'lunch', 'dinner'];
    final savedRecipes = app.saved
        .map(app.corpus.recipeOrNull)
        .whereType<Recipe>()
        .toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Display('week in pencil'),
        FilledButton.icon(
          onPressed: app.exportMealPlanToShopping,
          icon: const Icon(Icons.shopping_basket),
          label: const Text('export week to shopping list'),
        ),
        const SizedBox(height: 12),
        ...days.map(
          (day) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(day),
              ...meals.map((meal) {
                final slot = '$day.$meal';
                final recipeId = app.mealPlan[slot];
                return DragTarget<String>(
                  onAcceptWithDetails: (details) =>
                      app.moveMeal(details.data, slot),
                  builder: (context, _, _) => Card(
                    child: ListTile(
                      title: Text(meal),
                      subtitle: Text(
                        recipeId == null
                            ? 'tap to assign'
                            : L10n.pick(
                                app.corpus.recipeOrNull(recipeId)?.title ??
                                    {'en': 'unknown recipe'},
                                app.lang,
                              ),
                      ),
                      trailing: recipeId == null
                          ? null
                          : Draggable<String>(
                              data: slot,
                              feedback: Material(
                                child: Chip(label: Text(meal)),
                              ),
                              child: const Icon(Icons.drag_indicator),
                            ),
                      onTap: savedRecipes.isEmpty
                          ? null
                          : () => chooseRecipe(
                              context,
                              savedRecipes,
                              (recipe) => app.assignMeal(slot, recipe.id),
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

void chooseRecipe(
  BuildContext context,
  List<Recipe> recipes,
  ValueChanged<Recipe> onPick,
) {
  final app = AppScope.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: MorphTheme.paper,
    builder: (_) => ListView(
      children: recipes
          .map(
            (recipe) => ListTile(
              title: Text(L10n.pick(recipe.title, app.lang)),
              onTap: () {
                Navigator.pop(context);
                onPick(recipe);
              },
            ),
          )
          .toList(),
    ),
  );
}

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final grouped = Shopping.aggregate(
      app.shoppingRecipeIds.map(app.corpus.recipeOrNull).whereType<Recipe>(),
    );
    return Paper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('shopping list'),
          actions: [
            IconButton(
              onPressed: app.clearShopping,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Display('market notes'),
            if (grouped.isEmpty)
              const Note('add recipes to see unit-aware aggregation here'),
            ...grouped.entries.map(
              (entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(entry.key),
                  ...entry.value.map(
                    (line) => CheckboxListTile(
                      value: false,
                      onChanged: (_) {},
                      title: Text(
                        '${_amount(line.amount)} ${line.unit} ${L10n.pick(line.name, app.lang)}',
                      ),
                      subtitle: Text('from ${line.frequency} recipe(s)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final recipes = app.shoppingRecipeIds
        .map(app.corpus.recipeOrNull)
        .whereType<Recipe>()
        .toList();
    final lines = Shopping.aggregate(
      recipes,
    ).values.expand((line) => line).toList();
    final unique = lines.map((line) => line.id).toSet().length;
    final sorted = [...lines]
      ..sort((a, b) => b.frequency.compareTo(a.frequency));
    final months = <String, int>{};
    for (final entry in app.history) {
      final key =
          '${entry.cookedAt.year}-${entry.cookedAt.month.toString().padLeft(2, '0')}';
      months[key] = (months[key] ?? 0) + 1;
    }
    return Paper(
      child: Scaffold(
        appBar: AppBar(title: const Text('shopping insights')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Display('little market almanac'),
            StatCard(
              label: 'variety score',
              value: '$unique unique ingredients',
            ),
            const SectionTitle('top added'),
            ...sorted
                .take(10)
                .map(
                  (line) => ListTile(
                    title: Text(L10n.pick(line.name, app.lang)),
                    trailing: Text('×${line.frequency}'),
                  ),
                ),
            const SectionTitle('seasonal breakdown'),
            if (months.isEmpty)
              const Note('cook recipes to build monthly history'),
            ...months.entries.map(
              (entry) => ListTile(
                title: Text(entry.key),
                trailing: Text('${entry.value} cooked'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  var query = '';
  var category = 'all';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final categories = [
      'all',
      ...app.corpus.faqs.map((faq) => faq.category).toSet(),
    ];
    final faqs = app.corpus.faqs.where((faq) {
      final q = query.toLowerCase();
      return (category == 'all' || faq.category == category) &&
          (q.isEmpty ||
              L10n.pick(faq.question, app.lang).toLowerCase().contains(q) ||
              L10n.pick(faq.answer, app.lang).toLowerCase().contains(q));
    });
    return Paper(
      child: Scaffold(
        appBar: AppBar(title: const Text('help center')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Display('faq & field notes'),
            TextField(
              decoration: const InputDecoration(
                hintText: 'search faq',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => query = value),
            ),
            Wrap(
              spacing: 8,
              children: categories
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      onSelected: (_) => setState(() => category = item),
                    ),
                  )
                  .toList(),
            ),
            ...faqs.map(
              (faq) => ExpansionTile(
                title: Text(L10n.pick(faq.question, app.lang)),
                subtitle: Text(faq.category),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${L10n.pick(faq.answer, app.lang)}\n${faq.link}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpecificAvoidanceTypeahead extends StatefulWidget {
  const SpecificAvoidanceTypeahead({super.key});

  @override
  State<SpecificAvoidanceTypeahead> createState() =>
      _SpecificAvoidanceTypeaheadState();
}

class _SpecificAvoidanceTypeaheadState
    extends State<SpecificAvoidanceTypeahead> {
  var query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final profile = app.profile;
    final nodes = app.corpus.ingredients
        .expand((node) => node.flatten())
        .where((node) {
          final name = L10n.pick(node.name, app.lang).toLowerCase();
          return query.isEmpty ||
              name.contains(query.toLowerCase()) ||
              node.id.contains(query.toLowerCase());
        })
        .take(24)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'type apples, cilantro, bell peppers…',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: nodes
              .map(
                (node) => FilterChip(
                  label: Text(L10n.pick(node.name, app.lang)),
                  selected: profile.avoidIngredients.contains(node.id),
                  onSelected: (_) {
                    final next = {...profile.avoidIngredients};
                    next.contains(node.id)
                        ? next.remove(node.id)
                        : next.add(node.id);
                    app.updateProfile(profile.copyWith(avoidIngredients: next));
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final profile = app.profile;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Display('settings & preferences'),
        TextFormField(
          initialValue: profile.name,
          decoration: const InputDecoration(labelText: 'name'),
          onChanged: (value) =>
              app.updateProfile(profile.copyWith(name: value)),
        ),
        SwitchListTile(
          title: const Text('Deutsch'),
          value: profile.lang == 'de',
          onChanged: (value) =>
              app.updateProfile(profile.copyWith(lang: value ? 'de' : 'en')),
        ),
        const SectionTitle('class avoidance'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: app.corpus.ontology.compoundAvoidFlags.keys
              .followedBy(['pork', 'dairy', 'gluten', 'tree-nuts', 'shellfish'])
              .toSet()
              .map(
                (flag) => FilterChip(
                  label: Text(flag),
                  selected: profile.avoidFlags.contains(flag),
                  onSelected: (_) {
                    final next = {...profile.avoidFlags};
                    next.contains(flag) ? next.remove(flag) : next.add(flag);
                    app.updateProfile(profile.copyWith(avoidFlags: next));
                  },
                ),
              )
              .toList(),
        ),
        const Note(
          'Halal/kosher filters mean compatible ingredients only, never certification.',
        ),
        const SectionTitle('specific avoidance'),
        const SpecificAvoidanceTypeahead(),
        const SectionTitle('adaptation preferences'),
        SwitchListTile(
          title: const Text('show variant tags'),
          value: profile.showVariantTags,
          onChanged: (value) =>
              app.updateProfile(profile.copyWith(showVariantTags: value)),
        ),
        SwitchListTile(
          title: const Text('visual timer flash'),
          value: profile.visualAlertEnabled,
          onChanged: (value) =>
              app.updateProfile(profile.copyWith(visualAlertEnabled: value)),
        ),
        SwitchListTile(
          title: const Text('one-handed quick tap in cook mode'),
          value: profile.quickNextTapEnabled,
          onChanged: (value) =>
              app.updateProfile(profile.copyWith(quickNextTapEnabled: value)),
        ),
        Slider(
          value: profile.maxTimeMinutes.toDouble(),
          min: 15,
          max: 75,
          divisions: 4,
          label: '${profile.maxTimeMinutes}',
          onChanged: (value) => app.updateProfile(
            profile.copyWith(maxTimeMinutes: value.round()),
          ),
        ),
        Slider(
          value: profile.calorieTarget.toDouble(),
          min: 400,
          max: 800,
          divisions: 4,
          label: '${profile.calorieTarget}',
          onChanged: (value) =>
              app.updateProfile(profile.copyWith(calorieTarget: value.round())),
        ),
        Wrap(
          spacing: 8,
          children: ['easy', 'medium', 'hard']
              .map(
                (effort) => ChoiceChip(
                  label: Text(effort),
                  selected: profile.preferredEffort == effort,
                  onSelected: (_) => app.updateProfile(
                    profile.copyWith(preferredEffort: effort),
                  ),
                ),
              )
              .toList(),
        ),
        const DashedRule(),
        ListTile(
          leading: const Icon(Icons.shopping_basket_outlined),
          title: const Text('smart shopping list'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.insights_outlined),
          title: const Text('shopping insights'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InsightsScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('faq / help center'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FaqScreen()),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('backup / restore'),
          subtitle: const Text(
            'morphcook-backup.json and gzip bytes supported in service',
          ),
          onTap: () => showBackup(context),
        ),
      ],
    );
  }
}

void showBackup(BuildContext context) {
  final app = AppScope.of(context);
  final controller = TextEditingController(text: app.exportBackup());
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: MorphTheme.paper,
      title: const Text('morphcook-backup.json'),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: controller,
          maxLines: 12,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            app.restoreBackup(controller.text);
            Navigator.pop(context);
          },
          child: const Text('import text'),
        ),
        TextButton(
          onPressed: () => app.shareBackupFiles(),
          child: const Text('share json + gzip'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('done'),
        ),
      ],
    ),
  );
}

class CookModeScreen extends StatefulWidget {
  const CookModeScreen({required this.recipe, super.key});
  final Recipe recipe;

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  var index = 0;
  var servingsScale = 1.0;
  var remaining = 0;
  var timerRunning = false;
  var restoredProgress = false;
  DateTime lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    remaining = widget.recipe.steps.first.timerSeconds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (restoredProgress) return;
    restoredProgress = true;
    final progress = AppScope.of(context).cookProgress[widget.recipe.id];
    if (progress != null) {
      index = progress.stepIndex.clamp(0, widget.recipe.steps.length - 1);
      remaining = progress.remainingSeconds;
      servingsScale = progress.servingsScale;
    }
  }

  void persistProgress(AppState app) {
    app.saveCookProgress(
      CookProgress(
        recipeId: widget.recipe.id,
        stepIndex: index,
        remainingSeconds: remaining,
        servingsScale: servingsScale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final step = widget.recipe.steps[index];
    final lang = app.lang;
    return Scaffold(
      backgroundColor: const Color(0xff171412),
      body: AnimatedContainer(
        duration: app.profile.reduceMotion == true
            ? Duration.zero
            : const Duration(milliseconds: 180),
        color:
            remaining == 0 &&
                step.timerSeconds > 0 &&
                app.profile.visualAlertEnabled
            ? (index.isEven ? MorphTheme.coral : MorphTheme.teal).withValues(
                alpha: .22,
              )
            : const Color(0xff171412),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              if (!app.profile.quickNextTapEnabled) return;
              final now = DateTime.now();
              if (now.difference(lastTap).inMilliseconds < 300) return;
              lastTap = now;
              HapticFeedback.selectionClick();
              next(app);
            },
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        color: MorphTheme.paper,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                      const Spacer(),
                      Text(
                        '${index + 1}/${widget.recipe.steps.length}',
                        style: const TextStyle(
                          color: MorphTheme.paper,
                          fontFamily: 'JetBrains Mono',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    L10n.pick(widget.recipe.title, lang),
                    style: const TextStyle(
                      color: MorphTheme.paper,
                      fontFamily: 'Playfair Display',
                      fontSize: 34,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Slider(
                    value: servingsScale,
                    min: .5,
                    max: 2,
                    divisions: 3,
                    label:
                        '${(widget.recipe.servings * servingsScale).round()} servings',
                    onChanged: (value) => setState(() {
                      servingsScale = value;
                      persistProgress(app);
                    }),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        L10n.pick(step.text, lang),
                        style: const TextStyle(
                          color: MorphTheme.paper,
                          fontSize: 28,
                          height: 1.25,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (step.timerSeconds > 0)
                    Center(
                      child: TimerButton(
                        seconds: remaining,
                        running: timerRunning,
                        onTick: tick,
                        onToggle: () =>
                            setState(() => timerRunning = !timerRunning),
                      ),
                    ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: index == 0
                            ? null
                            : () => setState(() {
                                index--;
                                remaining =
                                    widget.recipe.steps[index].timerSeconds;
                                persistProgress(app);
                              }),
                        child: const Text('prev'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => next(app),
                        child: Text(
                          index == widget.recipe.steps.length - 1
                              ? 'complete'
                              : 'next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void tick() {
    if (!mounted || !timerRunning || remaining <= 0) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && timerRunning) {
        setState(() => remaining = max(0, remaining - 1));
        persistProgress(AppScope.of(context));
      }
      tick();
    });
  }

  void next(AppState app) {
    if (index == widget.recipe.steps.length - 1) {
      app.cooked(widget.recipe.id);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: MorphTheme.paper,
          title: const Text('done & delicious'),
          content: const Text('saved to local cooking history.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('back to recipe'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        index++;
        remaining = widget.recipe.steps[index].timerSeconds;
        timerRunning = false;
        persistProgress(app);
      });
    }
  }
}

class TimerButton extends StatefulWidget {
  const TimerButton({
    required this.seconds,
    required this.running,
    required this.onToggle,
    required this.onTick,
    super.key,
  });
  final int seconds;
  final bool running;
  final VoidCallback onToggle;
  final VoidCallback onTick;

  @override
  State<TimerButton> createState() => _TimerButtonState();
}

class _TimerButtonState extends State<TimerButton> {
  @override
  void didUpdateWidget(covariant TimerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.running && widget.running) widget.onTick();
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: widget.onToggle,
      icon: Icon(widget.running ? Icons.pause : Icons.play_arrow),
      label: Text(widget.seconds == 0 ? 'timer done' : '${widget.seconds}s'),
    );
  }
}

class Polaroid extends StatelessWidget {
  const Polaroid({
    required this.dish,
    required this.caption,
    required this.child,
    super.key,
  });
  final Dish dish;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -.018,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 22),
        decoration: BoxDecoration(
          color: const Color(0xfffffbf2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRect(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Stripes(color: dish.stripe, caption: ''),
                  ),
                  child,
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              style: const TextStyle(
                fontFamily: 'Caveat',
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Stripes extends StatelessWidget {
  const Stripes({required this.color, required this.caption, super.key});
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StripePainter(color),
      child: Container(
        alignment: Alignment.bottomRight,
        padding: const EdgeInsets.all(8),
        child: caption.isEmpty ? null : Mono(caption),
      ),
    );
  }
}

class StripePainter extends CustomPainter {
  StripePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: .28),
    );
    final paint = Paint()
      ..color = color.withValues(alpha: .55)
      ..strokeWidth = 10;
    for (var x = -size.height; x < size.width; x += 24) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StripePainter oldDelegate) =>
      oldDelegate.color != color;
}

class DashedRule extends StatelessWidget {
  const DashedRule({this.horizontalPadding = 0, super.key});
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 14, horizontal: horizontalPadding),
    child: CustomPaint(
      painter: DashPainter(),
      child: const SizedBox(height: 1, width: double.infinity),
    ),
  );
}

class DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MorphTheme.ink.withValues(alpha: .55)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Display extends StatelessWidget {
  const Display(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toLowerCase(), style: Theme.of(context).textTheme.displayLarge);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Mono(text.toUpperCase()),
  );
}

class Mono extends StatelessWidget {
  const Mono(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelMedium);
}

class Note extends StatelessWidget {
  const Note(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: MorphTheme.teal.withValues(alpha: .13),
      border: Border.all(color: MorphTheme.ink.withValues(alpha: .25)),
    ),
    child: Text(text),
  );
}

class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xfffffbf2),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Mono(label),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    ),
  );
}

String _amount(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);
