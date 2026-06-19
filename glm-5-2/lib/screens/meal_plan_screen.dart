import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class MealPlanScreen extends StatefulWidget {
  final String lang;
  const MealPlanScreen({super.key, required this.lang});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _startOfWeek(DateTime.now());
  }

  DateTime _startOfWeek(DateTime d) {
    final w = d.subtract(Duration(days: d.weekday - 1));
    return DateTime(w.year, w.month, w.day);
  }

  String _weekKey(DateTime start) {
    final diff = start.difference(DateTime(start.year, 1, 1)).inDays;
    final week = ((diff + DateTime(start.year, 1, 1).weekday - 1) / 7).floor() + 1;
    return '${start.year}-W${week.toString().padLeft(2, '0')}';
  }

  void _changeWeek(int delta) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * delta)));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final slots = ['breakfast', 'lunch', 'dinner'];
    final weekKey = _weekKey(_weekStart);

    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(
        title: 'meal plan',
        eyebrow: _fmtWeek(_weekStart),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: MorphColors.ink),
            onPressed: () => _changeWeek(-1),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: MorphColors.ink),
            onPressed: () => _changeWeek(1),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: MorphColors.coral),
            tooltip: 'export to shopping list',
            onPressed: () => _exportWeek(context, app, weekKey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 90, child: Text('slot', style: MorphFonts.label(size: 9))),
                ...days.map((d) => SizedBox(
                      width: 110,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(d, style: MorphFonts.label(size: 10, color: MorphColors.coral)),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            ...slots.map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(slot, style: MorphFonts.mono(size: 10, color: MorphColors.inkSoft)),
                        ),
                      ),
                      ...days.map((d) {
                        final key = '$d.$slot';
                        final recipeId = app.mealFor(weekKey, key);
                        final recipe = recipeId == null ? null : app.corpus.recipeIndex[recipeId];
                        final dish = recipe == null ? null : app.corpus.dishIndex[recipe.dishId];
                        return SizedBox(
                          width: 110,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: GestureDetector(
                              onTap: () => _assign(context, app, weekKey, key, recipeId),
                              onLongPress: () => app.assignMeal(weekKey: weekKey, slot: key, recipeId: null),
                              child: DragTarget<String>(
                                onAcceptWithDetails: (details) => app.assignMeal(weekKey: weekKey, slot: key, recipeId: details.data),
                                builder: (context, candidate, rejected) {
                                  return Container(
                                    height: 70,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: candidate.isNotEmpty ? MorphColors.coral : MorphColors.divider,
                                        width: candidate.isNotEmpty ? 2 : 1,
                                      ),
                                      color: recipe == null ? MorphColors.paperDeep.withOpacity(0.4) : MorphColors.paper,
                                    ),
                                    child: recipe == null
                                        ? Center(child: Text('+', style: MorphFonts.hand(size: 22, color: MorphColors.inkMuted)))
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (dish != null)
                                                Text(ltr(dish.canonicalName, widget.lang), style: MorphFonts.display(size: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 2),
                                              Text(ltr(recipe.title, widget.lang), style: MorphFonts.mono(size: 8, color: MorphColors.inkSoft), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            const DashedRule(),
            const SizedBox(height: 12),
            Text('long-press a slot to clear · drag a recipe card from cookbook to assign', style: MorphFonts.hand(size: 16, color: MorphColors.teal)),
          ],
        ),
      ),
    );
  }

  void _assign(BuildContext context, AppState app, String weekKey, String slot, String? current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MorphColors.paper,
      builder: (_) => _MealPicker(
        lang: widget.lang,
        onPick: (recipeId) {
          app.assignMeal(weekKey: weekKey, slot: slot, recipeId: recipeId);
          Navigator.pop(context);
        },
        onClear: current == null
            ? null
            : () {
                app.assignMeal(weekKey: weekKey, slot: slot, recipeId: null);
                Navigator.pop(context);
              },
      ),
    );
  }

  void _exportWeek(BuildContext context, AppState app, String weekKey) {
    final week = app.mealPlan[weekKey] ?? {};
    final recipeIds = week.values.toList();
    if (recipeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('nothing to export this week', style: MorphFonts.mono(size: 11)),
        backgroundColor: MorphColors.ink,
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ShoppingExport(recipeIds: recipeIds, lang: widget.lang)));
  }

  String _fmtWeek(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${start.day}.${start.month} – ${end.day}.${end.month}';
  }
}

class _MealPicker extends StatelessWidget {
  final String lang;
  final void Function(String) onPick;
  final VoidCallback? onClear;
  const _MealPicker({required this.lang, required this.onPick, this.onClear});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final saved = app.savedRecipes.map((e) => e.recipe).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('pick a recipe', style: MorphFonts.display(size: 22)),
            const DashedRule(),
            const SizedBox(height: 8),
            if (saved.isEmpty)
              Text('your cookbook is empty. save a variant first.', style: MorphFonts.hand(size: 16, color: MorphColors.teal))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: saved.length,
                  itemBuilder: (context, i) {
                    final r = saved[i];
                    final dish = app.corpus.dishIndex[r.dishId];
                    return LongPressDraggable<String>(
                      data: r.id,
                      feedback: Material(color: Colors.transparent, child: Container(
                        padding: const EdgeInsets.all(8),
                        color: MorphColors.ink,
                        child: Text(ltr(r.title, lang), style: MorphFonts.mono(size: 10, color: MorphColors.paper)),
                      )),
                      child: ListTile(
                        dense: true,
                        title: Text(ltr(r.title, lang), style: MorphFonts.serif(size: 15)),
                        subtitle: dish == null ? null : Text(ltr(dish.canonicalName, lang), style: MorphFonts.mono(size: 9, color: MorphColors.inkMuted)),
                        onTap: () => onPick(r.id),
                      ),
                    );
                  },
                ),
              ),
            if (onClear != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onClear, child: Text('clear slot', style: MorphFonts.mono(size: 11, color: MorphColors.coral))),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShoppingExport extends StatefulWidget {
  final List<String> recipeIds;
  final String lang;
  const _ShoppingExport({required this.recipeIds, required this.lang});

  @override
  State<_ShoppingExport> createState() => _ShoppingExportState();
}

class _ShoppingExportState extends State<_ShoppingExport> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = aggregate(app, widget.recipeIds);
    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(title: 'shopping list', eyebrow: 'from meal plan'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text('${list.length} unique items', style: MorphFonts.hand(size: 18, color: MorphColors.teal)),
          const SizedBox(height: 8),
          const DashedRule(),
          const SizedBox(height: 12),
          ...list.entries.map((e) => ListTile(
                dense: true,
                title: Text(e.key.name, style: MorphFonts.serif(size: 15)),
                subtitle: Text(e.key.aisle, style: MorphFonts.mono(size: 9, color: MorphColors.inkMuted)),
                trailing: Text('${_fmt(e.value.total)} ${e.key.unit}', style: MorphFonts.mono(size: 11, color: MorphColors.inkSoft)),
              )),
        ],
      ),
    );
  }
}

class _AggKey {
  final String id;
  final String name;
  final String unit;
  final String aisle;
  _AggKey(this.id, this.name, this.unit, this.aisle);
  @override
  int get hashCode => Object.hash(id, unit);
  @override
  bool operator ==(Object other) => other is _AggKey && other.id == id && other.unit == unit;
}

Map<_AggKey, ({double total, int recipes})> aggregate(AppState app, List<String> recipeIds) {
  final out = <_AggKey, ({double total, int recipes})>{};
  // unit conversion table: tbsp=15ml, tsp=5ml
  double toMl(String unit, double qty) {
    switch (unit) {
      case 'ml':
        return qty;
      case 'tbsp':
        return qty * 15;
      case 'tsp':
        return qty * 5;
      default:
        return double.nan;
    }
  }

  String normalizeUnit(String unit) {
    if (unit == 'ml' || unit == 'tbsp' || unit == 'tsp') return 'ml';
    return unit;
  }

  for (final id in recipeIds) {
    final r = app.corpus.recipeIndex[id];
    if (r == null) continue;
    for (final ing in r.ingredients) {
      final unit = normalizeUnit(ing.unit);
      final key = _AggKey(ing.id, ltr(ing.name, app.profile.lang), unit, ing.aisle);
      final existing = out[key];
      double qty;
      if (ing.unit == unit) {
        qty = ing.quantity;
      } else {
        final ml = toMl(ing.unit, ing.quantity);
        qty = ml.isNaN ? ing.quantity : ml;
      }
      if (existing == null) {
        out[key] = (total: qty, recipes: 1);
      } else {
        out[key] = (total: existing.total + qty, recipes: existing.recipes + 1);
      }
    }
  }
  // Sort by aisle then name.
  final sorted = out.entries.toList()
    ..sort((a, b) {
      final c = a.key.aisle.compareTo(b.key.aisle);
      if (c != 0) return c;
      return a.key.name.compareTo(b.key.name);
    });
  return {for (final e in sorted) e.key: e.value};
}

String _fmt(double q) {
  if (q == q.roundToDouble()) return q.toInt().toString();
  return q.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
}
