import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';

class IngredientInfoSheet extends StatelessWidget {
  final String ingredientId;
  final String lang;
  final AppState app;
  const IngredientInfoSheet({super.key, required this.ingredientId, required this.lang, required this.app});

  @override
  Widget build(BuildContext context) {
    final guide = app.corpus.ingredientGuide.where((e) => e.id == ingredientId).toList();
    final node = app.corpus.ingredientTree.find(ingredientId);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(node != null ? ltr(node.name, lang) : ingredientId, style: MorphFonts.display(size: 24))),
                  IconButton(
                    icon: const Icon(Icons.close, color: MorphColors.inkMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const DashedRule(),
              const SizedBox(height: 12),
              if (guide.isEmpty)
                Text('no guide entry for this ingredient yet.', style: MorphFonts.hand(size: 18, color: MorphColors.inkMuted))
              else ...[
                _Section('description', ltr(guide.first.description, lang)),
                _Section('usage', ltr(guide.first.usage, lang)),
                _Section('storage', ltr(guide.first.storage, lang)),
                _Section('where to find', ltr(guide.first.whereToFind, lang)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: MorphFonts.label(size: 10, color: MorphColors.coral)),
          const SizedBox(height: 4),
          Text(body, style: MorphFonts.serif(size: 15)),
        ],
      ),
    );
  }
}
