import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dish_detail.dart';
import 'faq_screen.dart';

class HomeFeed extends StatelessWidget {
  final String lang;
  const HomeFeed({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final visible = app.visibleDishesNow;
    final featured = visible.isNotEmpty ? visible.first : null;
    final rest = visible.length > 1 ? visible.sublist(1) : const [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _Masthead(app: app)),
        if (featured != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: FeaturedDishHero(
                dish: featured.dish,
                recipe: featured.bestVariant,
                lang: lang,
                onTap: () => _open(context, featured.dish.id),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text('tonight\'s lattice', style: MorphFonts.display(size: 22)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final entry = rest[i];
                final recipe = entry.bestVariant ?? entry.visibleVariants.first;
                return RecipeCard(
                  recipe: recipe,
                  dish: entry.dish,
                  lang: lang,
                  onTap: () => _open(context, entry.dish.id),
                  rotation: slightRotation(i + 3),
                );
              },
              childCount: rest.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const DashedRule(),
                const SizedBox(height: 12),
                Text('puzzled?', style: MorphFonts.hand(size: 24, color: MorphColors.coral)),
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FaqScreen(lang: lang))),
                  child: Text('open the help center', style: MorphFonts.mono(size: 12)),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  void _open(BuildContext context, String dishId) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => DishDetailScreen(dishId: dishId, lang: lang)));
  }
}

class _Masthead extends StatelessWidget {
  final AppState app;
  const _Masthead({required this.app});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 5
        ? 'late-night cook'
        : hour < 12
            ? 'good morning'
            : hour < 18
                ? 'good afternoon'
                : 'good evening';
    final name = app.profile.name.isEmpty ? '' : ', ${app.profile.name}';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: MorphColors.paper,
        border: Border(bottom: BorderSide(color: MorphColors.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('MorphCook', style: MorphFonts.display(size: 36)),
              const Spacer(),
              Text('est. 2026 · vol I', style: MorphFonts.mono(size: 9, color: MorphColors.inkMuted)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$greeting$name', style: MorphFonts.hand(size: 22, color: MorphColors.teal)),
        ],
      ),
    );
  }
}
