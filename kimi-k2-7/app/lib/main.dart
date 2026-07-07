import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/backup_service.dart';
import 'services/corpus_service.dart';
import 'services/data_store_service.dart';
import 'services/profile_service.dart';
import 'services/search_service.dart';
import 'services/shopping_service.dart';
import 'theme/app_theme.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/shell_screen.dart';
import 'utils/matching.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final corpus = CorpusService();
  await corpus.loadCore();

  final profile = ProfileService();
  await profile.init();

  final store = DataStoreService();
  await store.init();

  final shopping = ShoppingService(corpus: corpus, store: store);
  final backup = BackupService(profileService: profile, dataStore: store);
  final matcher = RecipeMatcher(
    ontology: corpus.ontology,
    ingredientTree: corpus.ingredientTree,
  );
  final search = SearchService(matcher: matcher);
  search.indexRecipes(corpus.recipes);

  runApp(
    MultiProvider(
      providers: [
        Provider<CorpusService>.value(value: corpus),
        ChangeNotifierProvider<ProfileService>.value(value: profile),
        ChangeNotifierProvider<DataStoreService>.value(value: store),
        ListenableProvider<ShoppingService>.value(value: shopping),
        Provider<BackupService>.value(value: backup),
        Provider<SearchService>.value(value: search),
      ],
      child: const MorphCookApp(),
    ),
  );
}

class MorphCookApp extends StatelessWidget {
  const MorphCookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileService>();
    return MaterialApp(
      title: 'MorphCook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: profile.onboarded ? const ShellScreen() : const OnboardingScreen(),
    );
  }
}
