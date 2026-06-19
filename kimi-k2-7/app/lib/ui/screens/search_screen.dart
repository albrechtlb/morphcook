import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recipe.dart';
import '../../services/corpus_service.dart';
import '../../services/data_store_service.dart';
import '../../services/profile_service.dart';
import '../../services/search_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../widgets/shared.dart';
import 'dish_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final List<Recipe> _results = [];
  String? _nextCursor;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String query, {bool refresh = true}) async {
    if (_loading) return;
    setState(() => _loading = true);
    final profile = context.read<ProfileService>().profile;
    final search = context.read<SearchService>();
    final store = context.read<DataStoreService>();
    try {
      if (refresh) {
        _results.clear();
        _nextCursor = null;
      }
      final result = search.search(
        query,
        profile: profile,
        lastCooked: store.lastCookedMap,
        cursor: _nextCursor,
      );
      _results.addAll(result.items);
      _nextCursor = result.nextCursor;
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<ProfileService>().profile.lang;
    return Scaffold(
      appBar: AppBar(title: const Text('search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(fontFamily: AppTheme.bodyFont, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Find a dish, ingredient, or tag',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) => _search(value),
              onChanged: (value) {
                if (value.isEmpty) _search('');
                if (value.length >= 3) _search(value);
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length + 1,
              itemBuilder: (context, index) {
                if (index == _results.length) {
                  if (_results.isEmpty && !_loading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('no results', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted)),
                      ),
                    );
                  }
                  if (_nextCursor != null) {
                    _search(_controller.text, refresh: false);
                  }
                  return _loading ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())) : const SizedBox.shrink();
                }
                final recipe = _results[index];
                final dish = context.read<CorpusService>().dishById(recipe.dishId);
                return ListTile(
                  title: Text(recipe.title.text(lang), style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text(recipe.subtitle.text(lang), style: Theme.of(context).textTheme.bodySmall),
                  trailing: ChipRow(labels: [recipe.diet, recipe.effort, '${recipe.caloriesPerServing}']),
                  onTap: () {
                    if (dish != null) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DishDetailScreen(dish: dish)));
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
