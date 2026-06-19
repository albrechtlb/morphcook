import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dish_detail.dart';

class CookbookScreen extends StatefulWidget {
  final String lang;
  const CookbookScreen({super.key, required this.lang});

  @override
  State<CookbookScreen> createState() => _CookbookScreenState();
}

class _CookbookScreenState extends State<CookbookScreen> {
  final _scrollController = ScrollController();
  static const _pageSize = 30;
  static const _maxRendered = 50;
  int _renderedCount = _pageSize;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 400 && !_loading) {
      _loadMore();
    }
  }

  void _loadMore() {
    final app = context.read<AppState>();
    final total = app.savedRecipes.length;
    if (_renderedCount >= total || _renderedCount >= _maxRendered) return;
    setState(() {
      _loading = true;
      _renderedCount = (_renderedCount + _pageSize).clamp(0, total);
      if (_renderedCount > _maxRendered) _renderedCount = _maxRendered;
    });
    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _loading = false));
  }

  void _refresh() {
    setState(() => _renderedCount = _pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.select<AppState, List<({dynamic recipe, DateTime savedAt})>>((s) => s.savedRecipes);
    final items = saved.take(_renderedCount).toList();
    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(
        title: 'cookbook',
        eyebrow: 'your saved variants',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: MorphColors.inkMuted, size: 20),
            onPressed: _refresh,
          ),
        ],
      ),
      body: saved.isEmpty
          ? _empty()
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: items.length + 1,
              itemBuilder: (context, i) {
                if (i == items.length) {
                  if (_loading) {
                    return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: MorphColors.inkMuted, strokeWidth: 2)));
                  }
                  if (_renderedCount >= saved.length || _renderedCount >= _maxRendered) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text('end of cookbook', style: MorphFonts.hand(size: 18, color: MorphColors.inkMuted))),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final e = items[i];
                final recipe = e.recipe;
                final dish = context.read<AppState>().corpus.dishForRecipe(recipe.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RecipeCard(
                    recipe: recipe,
                    dish: dish,
                    lang: widget.lang,
                    rotation: slightRotation(i + 1),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DishDetailScreen(dishId: dish?.id ?? recipe.dishId, lang: widget.lang, initialRecipeId: recipe.id),
                    )),
                  ),
                );
              },
            ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 48, color: MorphColors.inkMuted),
            const SizedBox(height: 12),
            Text('your cookbook is empty', style: MorphFonts.display(size: 22)),
            const SizedBox(height: 6),
            Text('save a specific variant — your döner, your way.', style: MorphFonts.hand(size: 18, color: MorphColors.teal), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
