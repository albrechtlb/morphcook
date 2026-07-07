import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/matching.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'dish_detail.dart';

class SearchScreen extends StatefulWidget {
  final String lang;
  const SearchScreen({super.key, required this.lang});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  final Set<String> _tagFilters = {};
  List<Recipe> _results = const [];
  static const _pageSize = 20;
  static const _maxRendered = 50;
  int _renderedCount = _pageSize;
  bool _hasMore = true;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch() {
    final app = context.read<AppState>();
    final q = _query.trim().toLowerCase();
    if (q.isEmpty && _tagFilters.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    // Log zero-result queries as content requests.
    final all = app.corpus.recipes.where((r) {
      final m = matchRecipe(r, app.profile, app.corpus.ontology);
      if (!m.visible) return false;
      if (q.isNotEmpty) {
        final title = ltr(r.title, widget.lang).toLowerCase();
        final tags = r.tags.map((t) => t.toLowerCase()).join(' ');
        final ingredients = r.ingredients.map((i) => ltr(i.name, widget.lang).toLowerCase()).join(' ');
        final haystack = '$title $tags $ingredients';
        if (!haystack.contains(q)) return false;
      }
      if (_tagFilters.isNotEmpty && !_tagFilters.every(r.tags.contains)) return false;
      return true;
    }).toList();
    setState(() {
      _results = all;
      _renderedCount = all.length < _pageSize ? all.length : _pageSize;
      _hasMore = all.length > _pageSize;
      if (all.isEmpty && q.isNotEmpty) app.logContentRequest(_query.trim());
    });
  }

  void _loadMore() {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        _renderedCount = (_renderedCount + _pageSize).clamp(0, _results.length);
        if (_renderedCount >= _results.length || _renderedCount >= _maxRendered) _hasMore = false;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final allTags = <String>{};
    for (final r in app.corpus.recipes.take(60)) {
      allTags.addAll(r.tags);
    }
    final popularTags = allTags.toList()..sort();
    final visible = _results.take(_renderedCount).toList();

    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(title: 'search', eyebrow: 'find a dish'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _controller,
              style: MorphFonts.serif(size: 18),
              decoration: InputDecoration(
                hintText: 'type a dish, ingredient, tag…',
                hintStyle: const TextStyle(color: MorphColors.inkMuted, fontStyle: FontStyle.italic),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.divider)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.coral, width: 2)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: MorphColors.ink, size: 22),
                  onPressed: _runSearch,
                ),
              ),
              onSubmitted: (_) => _runSearch(),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: popularTags.take(20).map((t) {
                final sel = _tagFilters.contains(t);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MorphChip(
                    label: t,
                    selected: sel,
                    onTap: () {
                      setState(() {
                        sel ? _tagFilters.remove(t) : _tagFilters.add(t);
                      });
                      _runSearch();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const DashedRule(),
          Expanded(
            child: _results.isEmpty && (_query.isNotEmpty || _tagFilters.isNotEmpty)
                ? _zeroResults()
                : visible.isEmpty
                    ? _initial()
                    : NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels > n.metrics.maxScrollExtent - 400 && !_loading && _hasMore) _loadMore();
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: visible.length + 1,
                          itemBuilder: (context, i) {
                            if (i == visible.length) {
                              if (_loading) {
                                return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: MorphColors.inkMuted, strokeWidth: 2)));
                              }
                              if (!_hasMore) {
                                return Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Center(child: Text('no more results', style: MorphFonts.hand(size: 16, color: MorphColors.inkMuted))),
                                );
                              }
                              return const SizedBox.shrink();
                            }
                            final r = visible[i];
                            final dish = app.corpus.dishIndex[r.dishId];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                              child: RecipeCard(
                                recipe: r,
                                dish: dish,
                                lang: widget.lang,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => DishDetailScreen(dishId: r.dishId, lang: widget.lang, initialRecipeId: r.id),
                                )),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _initial() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 48, color: MorphColors.inkMuted),
            const SizedBox(height: 12),
            Text('search every body\'s cookbook', style: MorphFonts.display(size: 22), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('profiles filter what you see — not what exists.', style: MorphFonts.hand(size: 16, color: MorphColors.teal), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _zeroResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_dissatisfied_outlined, size: 48, color: MorphColors.coral),
            const SizedBox(height: 12),
            Text('nothing here yet', style: MorphFonts.display(size: 22)),
            const SizedBox(height: 6),
            Text('your search is logged as a content request — it informs the corpus team.', style: MorphFonts.hand(size: 16, color: MorphColors.teal), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
