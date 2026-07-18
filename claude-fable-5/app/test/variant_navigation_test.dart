import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/data/app_state.dart';
import 'package:morphcook/data/store.dart';
import 'package:morphcook/models/profile.dart';
import 'package:morphcook/ui/theme.dart';
import 'package:morphcook/ui/widgets/recipe_row.dart';
import 'package:provider/provider.dart';

import 'helpers.dart';

Future<AppState> onboardedState() async {
  final corpus = await loadRealCorpus();
  final state = AppState(store: MemoryStore(), corpus: corpus);
  await state.load();
  await state
      .completeOnboarding(const Profile(name: 'cedric', lang: 'en'));
  return state;
}

Widget app(AppState state, Widget child) => ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(theme: morphTheme(), home: child),
    );

void main() {
  testWidgets(
      'tapping a result row opens exactly that variant, not the '
      'profile-best one', (tester) async {
    final state = (await tester.runAsync(onboardedState))!;
    final best = (await tester.runAsync(() => state.bestVariant('doener')))!;
    final variants =
        (await tester.runAsync(() => state.visibleVariants('doener')))!;
    // A variant the dish page would NOT pick on its own.
    final tapped = variants.firstWhere((r) => r.id != best.id);

    await tester.pumpWidget(
        app(state, Scaffold(body: RecipeRow(recipe: tapped))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(RecipeRow));
    await tester.pumpAndSettle();

    // The dish page must show the tapped variant's title — titles are
    // unique within a dish, so this pins the exact variant.
    expect(find.text(tapped.title.of('en').toLowerCase()), findsWidgets,
        reason: 'tapped ${tapped.id} but its title is not shown — the '
            'page probably fell back to the profile-best variant '
            '(${best.id})');
  });
}
