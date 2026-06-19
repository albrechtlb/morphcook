import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../models/models.dart';

/// A small "newspaper-style" recipe card showing title + time + calorie + stripe.
class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final Dish? dish;
  final String lang;
  final VoidCallback onTap;
  final double rotation;
  const RecipeCard({
    super.key,
    required this.recipe,
    this.dish,
    required this.lang,
    required this.onTap,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final d = dish;
    return PolaroidCard(
      rotation: rotation,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StripedPlaceholder(
              stripeColorHex: d?.stripeColor ?? '#9B8E7E',
              caption: d == null ? null : ltr(d.capCaption, lang),
              lang: lang,
              height: 120,
            ),
            const SizedBox(height: 10),
            Text(ltr(recipe.title, lang), style: MorphFonts.display(size: 18), maxLines: 2),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${recipe.timeMinutes}m', style: MorphFonts.mono(size: 10, color: MorphColors.inkMuted)),
                const SizedBox(width: 8),
                Text('~${recipe.caloriesPerServing}kcal', style: MorphFonts.mono(size: 10, color: MorphColors.inkMuted)),
                const SizedBox(width: 8),
                Text(recipe.effort, style: MorphFonts.mono(size: 10, color: MorphColors.teal)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Big featured dish hero with hero text + dish name.
class FeaturedDishHero extends StatelessWidget {
  final Dish dish;
  final Recipe? recipe;
  final String lang;
  final VoidCallback onTap;
  const FeaturedDishHero({super.key, required this.dish, this.recipe, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StripedPlaceholder(
            stripeColorHex: dish.stripeColor,
            caption: ltr(dish.capCaption, lang),
            lang: lang,
            height: 260,
          ),
          const SizedBox(height: 14),
          Text(ltr(dish.heroText, lang), style: MorphFonts.serif(size: 16, color: MorphColors.inkSoft), maxLines: 2),
          const SizedBox(height: 6),
          Text(ltr(dish.canonicalName, lang), style: MorphFonts.display(size: 44)),
          if (recipe != null) ...[
            const SizedBox(height: 4),
            Text('${ltr(recipe!.title, lang)} · ${recipe!.timeMinutes}m · ~${recipe!.caloriesPerServing}kcal',
                style: MorphFonts.mono(size: 11, color: MorphColors.inkMuted)),
          ],
        ],
      ),
    );
  }
}

/// Single chip used in variant switcher.
class MorphChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool muted;
  final bool disabled;
  final String? note;
  final VoidCallback? onTap;
  const MorphChip({
    super.key,
    required this.label,
    this.selected = false,
    this.muted = false,
    this.disabled = false,
    this.note,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? MorphColors.chipOn : (muted ? MorphColors.chipOff.withOpacity(0.55) : MorphColors.chipOff);
    final fg = selected ? MorphColors.paper : MorphColors.inkSoft;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: MorphColors.divider, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: MorphFonts.mono(size: 11, color: fg)),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(note!, style: MorphFonts.mono(size: 9, color: fg.withOpacity(0.8))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Save (bookmark) button.
class SaveButton extends StatelessWidget {
  final String recipeId;
  const SaveButton({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    final saved = context.select<AppState, bool>((s) => s.isSaved(recipeId));
    return IconButton(
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: MorphColors.ink, size: 22),
      onPressed: () => context.read<AppState>().toggleSaved(recipeId),
    );
  }
}

/// Cooking history pill ("cooked 12 days ago").
class HistoryPill extends StatelessWidget {
  final String recipeId;
  const HistoryPill({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context) {
    final last = context.select<AppState, DateTime?>((s) => s.lastCookedAt(recipeId));
    if (last == null) return const SizedBox.shrink();
    final days = DateTime.now().difference(last).inDays;
    return Text(
      days == 0 ? 'cooked today' : 'cooked ${days}d ago',
      style: MorphFonts.hand(size: 14, color: MorphColors.coral),
    );
  }
}

/// Generates a deterministic slight rotation for visual variety.
double slightRotation(int seed) {
  final r = Random(seed);
  return (r.nextDouble() - 0.5) * 0.06;
}
