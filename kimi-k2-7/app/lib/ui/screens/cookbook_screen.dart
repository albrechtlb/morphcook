import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/corpus_service.dart';
import '../../services/data_store_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';
import '../widgets/shared.dart';
import 'dish_detail_screen.dart';

class CookbookScreen extends StatelessWidget {
  const CookbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final corpus = context.read<CorpusService>();
    final store = context.watch<DataStoreService>();
    final lang = context.read<ProfileService>().profile.lang;
    final savedRecipes = store.savedRecipeIds
        .map((id) => corpus.recipeById(id))
        .whereType()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('your cookbook')),
      body: savedRecipes.isEmpty
          ? Center(
              child: Text(
                'no saved recipes yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
            )
          : ListView.builder(
              itemCount: savedRecipes.length,
              itemBuilder: (context, index) {
                final recipe = savedRecipes[index];
                final dish = corpus.dishById(recipe.dishId);
                return Dismissible(
                  key: Key(recipe.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.coral,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => store.toggleSaved(recipe.id),
                  child: ListTile(
                    leading: dish != null
                        ? SizedBox(
                            width: 50,
                            height: 50,
                            child: StripedPlaceholder(color: dish.stripeColor.toColor()),
                          )
                        : null,
                    title: Text(recipe.title.text(lang), style: Theme.of(context).textTheme.titleLarge),
                    subtitle: Text(recipe.subtitle.text(lang), style: Theme.of(context).textTheme.bodySmall),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark, color: AppColors.ink),
                      onPressed: () => store.toggleSaved(recipe.id),
                    ),
                    onTap: () {
                      if (dish != null) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => DishDetailScreen(dish: dish)));
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
