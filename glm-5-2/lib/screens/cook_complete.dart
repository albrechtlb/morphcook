import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class CookCompleteScreen extends StatelessWidget {
  final String recipeId;
  final String lang;
  const CookCompleteScreen({super.key, required this.recipeId, required this.lang});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final recipe = app.corpus.recipeIndex[recipeId];
    final dish = app.corpus.dishForRecipe(recipeId);
    return Scaffold(
      backgroundColor: MorphColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Center(child: Text('done', style: MorphFonts.display(size: 80, color: MorphColors.coral))),
              const SizedBox(height: 12),
              Center(child: Text('you cooked it.', style: MorphFonts.hand(size: 28, color: MorphColors.teal))),
              const SizedBox(height: 24),
              if (recipe != null)
                Center(child: Text(ltr(recipe.title, lang), style: MorphFonts.serif(size: 20), textAlign: TextAlign.center)),
              if (dish != null)
                Center(child: Text(ltr(dish.canonicalName, lang), style: MorphFonts.mono(size: 11, color: MorphColors.inkMuted))),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MorphColors.ink,
                        side: const BorderSide(color: MorphColors.ink),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text('home', style: MorphFonts.mono(size: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => _SavePrompt(recipeId: recipeId),
                      )),
                      style: FilledButton.styleFrom(
                        backgroundColor: MorphColors.ink,
                        foregroundColor: MorphColors.paper,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text('save', style: MorphFonts.mono(size: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavePrompt extends StatelessWidget {
  final String recipeId;
  const _SavePrompt({required this.recipeId});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final saved = app.isSaved(recipeId);
    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(title: 'saved', eyebrow: 'cookbook', showBack: true),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(saved ? 'already in your cookbook.' : 'added to your cookbook.', style: MorphFonts.display(size: 26)),
            const SizedBox(height: 8),
            Text(saved ? 'this variant was already there.' : 'your specific variant is saved — not just the dish.',
                style: MorphFonts.hand(size: 20, color: MorphColors.teal)),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: FilledButton.styleFrom(
                backgroundColor: MorphColors.ink,
                foregroundColor: MorphColors.paper,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text('done', style: MorphFonts.mono(size: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
