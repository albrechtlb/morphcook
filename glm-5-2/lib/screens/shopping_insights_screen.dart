import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ShoppingInsightsScreen extends StatelessWidget {
  final String lang;
  const ShoppingInsightsScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final saved = app.savedRecipes;
    // Aggregate from saved recipes
    final counts = <String, int>{};
    final byMonth = <String, int>{};
    for (final entry in saved) {
      for (final ing in entry.recipe.ingredients) {
        counts[ing.id] = (counts[ing.id] ?? 0) + 1;
      }
    }
    final history = app.history;
    for (final h in history) {
      final ym = '${h.cookedAt.year}-${h.cookedAt.month.toString().padLeft(2, '0')}';
      byMonth[ym] = (byMonth[ym] ?? 0) + 1;
    }
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final months = byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final varietyScore = counts.length;

    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(title: 'shopping insights', eyebrow: 'analytics'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text('variety score', style: MorphFonts.label(size: 11)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$varietyScore', style: MorphFonts.display(size: 56, color: MorphColors.coral)),
              const SizedBox(width: 6),
              Text('unique ingredients across ${saved.length} saved recipes', style: MorphFonts.hand(size: 16, color: MorphColors.teal)),
            ],
          ),
          const SizedBox(height: 20),
          const DashedRule(),
          const SizedBox(height: 12),
          Text('top ingredients', style: MorphFonts.label(size: 11)),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Text('save recipes to see what you reach for most.', style: MorphFonts.hand(size: 16, color: MorphColors.inkMuted))
          else
            ...top.take(8).map((e) {
              final node = app.corpus.ingredientTree.find(e.key);
              final name = node != null ? ltr(node.name, lang) : e.key;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(name, style: MorphFonts.serif(size: 15))),
                    Text('×${e.value}', style: MorphFonts.mono(size: 11, color: MorphColors.inkSoft)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: e.value / top.first.value,
                        backgroundColor: MorphColors.chipOff,
                        color: MorphColors.coral,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),
          const DashedRule(),
          const SizedBox(height: 12),
          Text('seasonal breakdown (cooked)', style: MorphFonts.label(size: 11)),
          const SizedBox(height: 8),
          if (months.isEmpty)
            Text('cook a few recipes — your monthly rhythm will show here.', style: MorphFonts.hand(size: 16, color: MorphColors.inkMuted))
          else
            ...months.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 90, child: Text(e.key, style: MorphFonts.mono(size: 11, color: MorphColors.inkSoft))),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: e.value / (months.first.value == 0 ? 1 : months.map((m) => m.value).reduce((a, b) => a > b ? a : b)),
                          backgroundColor: MorphColors.chipOff,
                          color: MorphColors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('×${e.value}', style: MorphFonts.mono(size: 10, color: MorphColors.inkMuted)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}
