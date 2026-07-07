import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ingredient.dart';
import '../../models/profile.dart';
import '../../services/backup_service.dart';
import '../../services/corpus_service.dart';
import '../../services/data_store_service.dart';
import '../../services/profile_service.dart';
import 'faq_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileService>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _Section(title: 'profile', children: [
            ListTile(
              title: const Text('name'),
              trailing: Text(profile.name.isEmpty ? '—' : profile.name),
              onTap: () => _editName(context),
            ),
            ListTile(
              title: const Text('language'),
              trailing: Text(profile.lang.toUpperCase()),
              onTap: () => _pickLanguage(context),
            ),
          ]),
          _Section(title: 'diet & preferences', children: [
            ListTile(
              title: const Text('avoided flags'),
              subtitle: Text(profile.avoidFlags.isEmpty ? 'none set' : profile.avoidFlags.join(', ')),
              onTap: () => _editAvoidFlags(context),
            ),
            ListTile(
              title: const Text('avoided ingredients'),
              subtitle: Text(profile.avoidIngredients.isEmpty ? 'none set' : profile.avoidIngredients.take(5).join(', ')),
              onTap: () => _editAvoidIngredients(context),
            ),
            ListTile(
              title: const Text('calorie target'),
              trailing: Text('${profile.calorieTarget} kcal'),
              onTap: () => _editNumber(context, 'calorie target', profile.calorieTarget, (v) => _save(context, profile.copyWith(calorieTarget: v)), max: 3000),
            ),
            ListTile(
              title: const Text('time budget'),
              trailing: Text('${profile.maxTimeMinutes} min'),
              onTap: () => _editNumber(context, 'time budget', profile.maxTimeMinutes, (v) => _save(context, profile.copyWith(maxTimeMinutes: v)), max: 300),
            ),
          ]),
          _Section(title: 'accessibility', children: [
            SwitchListTile(
              title: const Text('reduce motion'),
              value: profile.reduceMotion ?? false,
              onChanged: (v) => _save(context, profile.copyWith(reduceMotion: v)),
            ),
            SwitchListTile(
              title: const Text('visual timer alerts'),
              value: profile.visualAlertEnabled,
              onChanged: (v) => _save(context, profile.copyWith(visualAlertEnabled: v)),
            ),
            SwitchListTile(
              title: const Text('quick-tap next step'),
              value: profile.quickNextTapEnabled,
              onChanged: (v) => _save(context, profile.copyWith(quickNextTapEnabled: v)),
            ),
          ]),
          _Section(title: 'data', children: [
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('backup & restore'),
              onTap: () => _showBackup(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('help center'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FAQScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('reset all data'),
              onTap: () => _confirmReset(context),
            ),
          ]),
          _Section(title: 'about', children: [
            const ListTile(title: Text('MorphCook v1.0.0'), subtitle: Text('Your cookbook, for every body.')),
            ListTile(
              title: const Text('content notes'),
              subtitle: const Text('We never claim halal or kosher certification; recipes indicate compatibility only.'),
            ),
          ]),
        ],
      ),
    );
  }

  void _save(BuildContext context, Profile profile) {
    context.read<ProfileService>().saveProfile(profile);
  }

  Future<void> _editName(BuildContext context) async {
    final profile = context.read<ProfileService>().profile;
    final controller = TextEditingController(text: profile.name);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('your name'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('save')),
        ],
      ),
    );
    if (value != null) _save(context, profile.copyWith(name: value));
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final profile = context.read<ProfileService>().profile;
    final lang = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('language / sprache'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'en'), child: const Text('English')),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, 'de'), child: const Text('Deutsch')),
        ],
      ),
    );
    if (lang != null) _save(context, profile.copyWith(lang: lang));
  }

  Future<void> _editNumber(BuildContext context, String label, int current, ValueChanged<int> onSave, {required int max}) async {
    final controller = TextEditingController(text: current.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)), child: const Text('save')),
        ],
      ),
    );
    if (value != null) onSave(value.clamp(1, max));
  }

  Future<void> _editAvoidFlags(BuildContext context) async {
    final profile = context.read<ProfileService>().profile;
    final ontology = context.read<CorpusService>().ontology;
    if (ontology == null) return;
    final flags = ontology.containsFlags.keys.toList()..addAll(ontology.compoundFlags.keys);
    await showDialog(
      context: context,
      builder: (ctx) => _FlagPickerDialog(
        flags: flags,
        selected: profile.avoidFlags,
        onSave: (selected) => _save(context, profile.copyWith(avoidFlags: selected)),
      ),
    );
  }

  Future<void> _editAvoidIngredients(BuildContext context) async {
    final profile = context.read<ProfileService>().profile;
    final tree = context.read<CorpusService>().ingredientTree;
    if (tree == null) return;
    await showDialog(
      context: context,
      builder: (ctx) => _IngredientPickerDialog(
        tree: tree,
        selected: profile.avoidIngredients,
        onSave: (selected) => _save(context, profile.copyWith(avoidIngredients: selected)),
      ),
    );
  }

  Future<void> _showBackup(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => _BackupSheet(),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('reset everything?'),
        content: const Text('This clears all saved recipes, meal plans, and shopping data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('reset')),
        ],
      ),
    );
    if (ok == true) {
      await context.read<DataStoreService>().clearSaved();
      await context.read<DataStoreService>().clearMealPlan();
      await context.read<DataStoreService>().clearShopping();
      await context.read<DataStoreService>().clearHistory();
      await context.read<DataStoreService>().clearContentRequests();
      await context.read<ProfileService>().clear();
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.displaySmall),
        ),
        ...children,
      ],
    );
  }
}

class _FlagPickerDialog extends StatefulWidget {
  final List<String> flags;
  final Set<String> selected;
  final ValueChanged<Set<String>> onSave;
  const _FlagPickerDialog({required this.flags, required this.selected, required this.onSave});

  @override
  State<_FlagPickerDialog> createState() => _FlagPickerDialogState();
}

class _FlagPickerDialogState extends State<_FlagPickerDialog> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selected};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.flags.where((f) => f.toLowerCase().contains(_query.toLowerCase())).toList();
    return AlertDialog(
      title: const Text('avoided flags'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'search'),
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: ListView(
                children: filtered.map((f) => CheckboxListTile(
                  title: Text(f),
                  value: _selected.contains(f),
                  onChanged: (v) => setState(() {
                    if (v == true) _selected.add(f); else _selected.remove(f);
                  }),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('cancel')),
        TextButton(onPressed: () {
          widget.onSave(_selected);
          Navigator.pop(context);
        }, child: const Text('save')),
      ],
    );
  }
}

class _IngredientPickerDialog extends StatefulWidget {
  final AvoidanceTree tree;
  final Set<String> selected;
  final ValueChanged<Set<String>> onSave;
  const _IngredientPickerDialog({required this.tree, required this.selected, required this.onSave});

  @override
  State<_IngredientPickerDialog> createState() => _IngredientPickerDialogState();
}

class _IngredientPickerDialogState extends State<_IngredientPickerDialog> {
  late Set<String> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selected};
  }

  List<IngredientNode> get _flat => widget.tree.root.flatten();

  @override
  Widget build(BuildContext context) {
    final items = _flat.where((node) => node.name.text('en').toLowerCase().contains(_query.toLowerCase())).toList();
    return AlertDialog(
      title: const Text('avoided ingredients'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(hintText: 'search ingredients'),
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: ListView(
                children: items.map<Widget>((node) => CheckboxListTile(
                  title: Text(node.name.text('en')),
                  value: _selected.contains(node.id),
                  onChanged: (v) => setState(() {
                    if (v == true) _selected.add(node.id); else _selected.remove(node.id);
                  }),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('cancel')),
        TextButton(onPressed: () {
          widget.onSave(_selected);
          Navigator.pop(context);
        }, child: const Text('save')),
      ],
    );
  }
}

class _BackupSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('backup & restore', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('export backup'),
            onTap: () async {
              final service = context.read<BackupService>();
              await service.export(sharePlain: true, shareCompressed: true);
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('import backup'),
            onTap: () async {
              final service = context.read<BackupService>();
              try {
                await service.importFromFile(replace: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored')));
                  Navigator.pop(context);
                }
              } on DecryptionException catch (e) {
                if (e.reason.toLowerCase().contains('password')) {
                  final password = await _askPassword(context);
                  if (password != null) {
                    await service.importFromFile(password: password, replace: true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored')));
                      Navigator.pop(context);
                    }
                  }
                } else {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.reason)));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _askPassword(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('backup password'),
        content: TextField(controller: controller, obscureText: true, decoration: const InputDecoration(hintText: 'password')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('unlock')),
        ],
      ),
    );
  }
}
