import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shopping_and_backup.dart';
import '../../services/shopping_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  Set<String> _checked = {};
  bool _showInsights = false;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ShoppingService>();
    final items = service.items;
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.aisle, () => []).add(item);
    }
    final insights = service.generateInsights();

    return Scaffold(
      appBar: AppBar(
        title: const Text('shopping list'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => setState(() => _showInsights = !_showInsights),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => service.clear(),
          ),
        ],
      ),
      body: items.isEmpty
          ? const _Empty()
          : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (_showInsights) _InsightsPanel(insights: insights),
                ...grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(entry.key, style: TextStyle(fontFamily: AppTheme.handFont, fontSize: 22, color: AppColors.coral)),
                      ),
                      ...entry.value.map((item) {
                        final checked = _checked.contains(item.ingredientId);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _checked.add(item.ingredientId);
                              } else {
                                _checked.remove(item.ingredientId);
                              }
                            });
                          },
                          title: Text(
                            '${_fmt(item.quantity)}${item.unit != null ? ' ${item.unit}' : ''} ${item.displayName}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  decoration: checked ? TextDecoration.lineThrough : null,
                                  color: checked ? AppColors.inkMuted : AppColors.ink,
                                ),
                          ),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => service.removeItem(item.ingredientId),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
    );
  }

  String _fmt(double v) {
    return v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(1);
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.inkMuted),
          const SizedBox(height: 12),
          Text('Your list is empty', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted)),
          const SizedBox(height: 8),
          Text('Add from a recipe or meal plan', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}

class _InsightsPanel extends StatelessWidget {
  final ShoppingInsights insights;
  const _InsightsPanel({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('insights', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('unique ingredients: ${insights.uniqueIngredientCount}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            if (insights.topIngredients.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('top ingredients', style: Theme.of(context).textTheme.bodySmall),
                  Wrap(
                    spacing: 8,
                    children: insights.topIngredients.map((e) => Chip(label: Text('${e.key} (${e.value}'))).toList(),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text('this month: ${insights.monthlyCounts.entries.firstOrNull?.value ?? 0} items', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
