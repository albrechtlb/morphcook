import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dish.dart';
import '../../models/profile.dart';
import '../../models/recipe.dart';
import '../../services/corpus_service.dart';
import '../../services/data_store_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/matching.dart';
import '../widgets/shared.dart';
import 'dish_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final corpus = context.read<CorpusService>();
    final profile = context.read<ProfileService>().profile;
    final store = context.read<DataStoreService>();
    final matcher = RecipeMatcher(
      ontology: corpus.ontology,
      ingredientTree: corpus.ingredientTree,
    );
    final lastCooked = store.lastCookedMap;

    final featured = _pickFeatured(corpus, profile, lastCooked, matcher);

    return Scaffold(
      appBar: AppBar(
        title: const Text('morphcook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          _Masthead(profile: profile),
          const SizedBox(height: 24),
          if (featured != null) _FeaturedCard(dish: featured.dish, recipe: featured.recipe, matcher: matcher),
          const SizedBox(height: 24),
          Text('discover', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          _DishGrid(corpus: corpus, profile: profile, matcher: matcher),
        ],
      ),
    );
  }

  ({Dish dish, Recipe recipe})? _pickFeatured(
    CorpusService corpus,
    Profile profile,
    Map<String, DateTime> lastCooked,
    RecipeMatcher matcher,
  ) {
    Recipe? best;
    Dish? bestDish;
    int bestScore = -1;
    for (final dish in corpus.dishes) {
      final variants = corpus.recipesForDish(dish.id);
      final visible = variants.where((r) => matcher.visible(r, profile)).toList();
      if (visible.isEmpty) continue;
      for (final recipe in visible) {
        final score = matcher.timeAwareBonus(recipe, DateTime.now()) +
            matcher.stalenessBonus(recipe, lastCooked) +
            matcher.scoreVariant(recipe, profile);
        if (score > bestScore) {
          bestScore = score;
          best = recipe;
          bestDish = dish;
        }
      }
    }
    if (best == null || bestDish == null) return null;
    return (dish: bestDish, recipe: best);
  }
}

class _Masthead extends StatelessWidget {
  final Profile profile;
  const _Masthead({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('your cookbook,', style: Theme.of(context).textTheme.displayLarge),
        Text('for every body', style: Theme.of(context).textTheme.displayLarge),
        const SizedBox(height: 8),
        Text(
          'good ${profile.name.isNotEmpty ? 'evening, ${profile.name}' : 'evening'}',
          style: TextStyle(fontFamily: 'Caveat', fontSize: 22, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Dish dish;
  final Recipe recipe;
  final RecipeMatcher matcher;
  const _FeaturedCard({required this.dish, required this.recipe, required this.matcher});

  @override
  Widget build(BuildContext context) {
    final lang = context.read<ProfileService>().profile.lang;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DishDetailScreen(dish: dish))),
      child: PolaroidCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StripedPlaceholder(
              color: dish.stripeColor.toColor(),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'featured',
                  style: TextStyle(fontFamily: 'Caveat', fontSize: 28, color: AppColors.ink),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dish.canonicalName.text(lang), style: Theme.of(context).textTheme.headlineMedium),
                  Text('${recipe.timeMinutes} min', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(recipe.subtitle.text(lang), style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: ChipRow(
                labels: [...recipe.attributes.where((a) => !a.startsWith('≤') && a != recipe.effort).take(3), recipe.effort],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DishGrid extends StatelessWidget {
  final CorpusService corpus;
  final Profile profile;
  final RecipeMatcher matcher;
  const _DishGrid({required this.corpus, required this.profile, required this.matcher});

  @override
  Widget build(BuildContext context) {
    final lang = profile.lang;
    return Column(
      children: corpus.dishes.map((dish) {
        return _DishListTile(dish: dish, lang: lang);
      }).toList(),
    );
  }
}

class _DishListTile extends StatelessWidget {
  final Dish dish;
  final String lang;
  const _DishListTile({required this.dish, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DishDetailScreen(dish: dish))),
      leading: SizedBox(
        width: 60,
        height: 60,
        child: StripedPlaceholder(color: dish.stripeColor.toColor()),
      ),
      title: Text(dish.canonicalName.text(lang), style: Theme.of(context).textTheme.titleLarge),
      subtitle: Text(dish.capCaption.text(lang), style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.arrow_forward, color: AppColors.inkMuted),
    );
  }
}
