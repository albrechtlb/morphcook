import '../models/recipe.dart';
import '../models/profile.dart';
import '../utils/matching.dart';

class SearchResult {
  final List<Recipe> items;
  final String? nextCursor;

  SearchResult({required this.items, this.nextCursor});
}

class SearchService {
  final RecipeMatcher matcher;

  // recipe id -> tokens by language
  final Map<String, Map<String, Set<String>>> _index = {};
  final Map<String, Recipe> _recipes = {};

  SearchService({required this.matcher});

  void indexRecipes(List<Recipe> recipes) {
    _index.clear();
    _recipes.clear();
    for (final recipe in recipes) {
      _recipes[recipe.id] = recipe;
      _index[recipe.id] = {};
      for (final lang in {...recipe.title.values.keys, ...recipe.subtitle.values.keys, 'en'}) {
        final tokens = <String>{};
        tokens.addAll(_tokenize(recipe.title.text(lang)));
        tokens.addAll(_tokenize(recipe.subtitle.text(lang)));
        for (final tag in recipe.tags) tokens.addAll(_tokenize(tag));
        for (final ing in recipe.ingredients) {
          tokens.addAll(_tokenize(ing.name.text(lang)));
        }
        _index[recipe.id]![lang] = tokens;
      }
    }
  }

  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  SearchResult search(
    String query, {
    required Profile profile,
    required Map<String, DateTime> lastCooked,
    String? cursor,
    DateTime? now,
  }) {
    final pageSize = 20;
    final offset = (cursor == null) ? 0 : int.tryParse(cursor) ?? 0;
    final lang = profile.lang;
    final queryTokens = _tokenize(query);
    final nowDt = now ?? DateTime.now();

    final scored = <_ScoredRecipe>[];
    for (final recipe in _index.keys.map((id) => _recipeById(id)).whereType<Recipe>()) {
      if (!matcher.visible(recipe, profile)) continue;
      final indexTokens = _index[recipe.id]?[lang] ?? _index[recipe.id]?['en'] ?? <String>{};
      int matchScore = 0;
      for (final token in queryTokens) {
        if (indexTokens.contains(token)) matchScore += 10;
      }
      if (queryTokens.isNotEmpty && matchScore == 0) continue;
      // Empty query passes through, rank purely by bonuses.
      int bonus = matcher.timeAwareBonus(recipe, nowDt) + matcher.stalenessBonus(recipe, lastCooked);
      scored.add(_ScoredRecipe(recipe: recipe, score: matchScore + bonus + _popularityScore(recipe)));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final total = scored.length;
    final nextOffset = offset + pageSize;
    final items = scored.skip(offset).take(pageSize).map((s) => s.recipe).toList();
    String? nextCursor;
    if (nextOffset < total) {
      nextCursor = nextOffset.toString();
    }
    return SearchResult(items: items, nextCursor: nextCursor);
  }

  int _popularityScore(Recipe recipe) {
    return recipe.ingredients.length; // arbitrary tie-breaker
  }

  Recipe? _recipeById(String id) => _recipes[id];
}

class _ScoredRecipe {
  final Recipe recipe;
  final int score;
  _ScoredRecipe({required this.recipe, required this.score});
}
