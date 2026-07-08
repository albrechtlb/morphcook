import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphcook/data/app_state.dart';
import 'package:morphcook/data/store.dart';
import 'package:morphcook/main.dart';
import 'package:morphcook/models/collections.dart';
import 'package:morphcook/models/profile.dart';
import 'package:morphcook/ui/screens/dish_detail_screen.dart';
import 'package:morphcook/ui/theme.dart';
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
      'planning a batch cook offers leftovers, marks the slot and keeps '
      'the export single', (tester) async {
    final state = (await tester.runAsync(onboardedState))!;
    final recipe = (await tester.runAsync(
        () => state.corpus.recipeById('doener-vegan')))!;
    expect(recipe.servings, greaterThanOrEqualTo(2),
        reason: 'test needs a multi-serving recipe');
    await state.toggleSaved(recipe.id);

    await tester.pumpWidget(app(state, const RootShell()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('plan'));
    await tester.pumpAndSettle();

    // Monday breakfast is the first empty slot cell.
    await tester.tap(find.text('tap to plan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('from your cookbook'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(recipe.title.of('en').toLowerCase()).first);
    await tester.pumpAndSettle();

    // The leftover offer shows; plan one leftover meal.
    expect(find.text('plan the leftovers?'), findsOneWidget);
    await tester.tap(find.text('1 × leftovers'));
    await tester.pumpAndSettle();

    final weekKey = isoWeekKey(weekStart(DateTime.now()));
    final week = state.mealPlan[weekKey]!;
    expect(week['mon.breakfast'], recipe.id);
    expect(week['mon.lunch'], leftoverEntry(recipe.id));

    // The plan screen shows the leftover badge and a day-calorie sum.
    expect(find.text('↩ leftovers'), findsOneWidget);
    expect(find.textContaining('kcal'), findsWidgets);

    // Export buys the cook once — the leftover slot adds nothing.
    // (Let the confirmation snackbar clear the button first.)
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('send week to shopping list'));
    await tester.pumpAndSettle();
    final aggregatedOnce = state.shoppingList.length;
    expect(aggregatedOnce, recipe.ingredients.length);
  });

  testWidgets('portion stepper scales ingredient quantities and the '
      'shopping export', (tester) async {
    final state = (await tester.runAsync(onboardedState))!;
    await tester
        .pumpWidget(app(state, const DishDetailScreen(dishId: 'doener')));
    await tester.pumpAndSettle();

    final recipe = (await tester.runAsync(
        () => state.bestVariant('doener')))!;
    final base = recipe.servings;
    final firstIngredient = recipe.ingredients.first;

    // The ingredients section sits below the fold of the test viewport.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    // Stepper shows the recipe's own serving count.
    expect(find.text('$base'), findsWidgets);

    await tester.ensureVisible(find.byIcon(Icons.add_circle_outline));
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    // First ingredient line scaled by (base + 1) / base.
    final scaled = firstIngredient.qty * (base + 1) / base;
    final scaledText = scaled == scaled.roundToDouble()
        ? scaled.round().toString()
        : ((scaled * 100).roundToDouble() / 100).toString();
    expect(find.textContaining(scaledText), findsWidgets);

    // Shopping export carries the scale factor.
    await tester.ensureVisible(find.text('add to shopping list'));
    await tester.tap(find.text('add to shopping list'));
    await tester.pumpAndSettle();
    final item = state.shoppingList.firstWhere(
        (i) => i.ingredientId == firstIngredient.ingredientId);
    expect(item.qty, closeTo(scaled, 0.01));
  });

  testWidgets('fridge life renders on the dish detail meta strip',
      (tester) async {
    final state = (await tester.runAsync(onboardedState))!;
    await tester
        .pumpWidget(app(state, const DishDetailScreen(dishId: 'doener')));
    await tester.pumpAndSettle();
    expect(find.textContaining('days in the fridge'), findsOneWidget);
  });
}
