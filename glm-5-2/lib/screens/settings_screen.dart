import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'faq_screen.dart';
import 'shopping_insights_screen.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String lang;
  const SettingsScreen({super.key, required this.lang});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.profile;
    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(title: 'settings', eyebrow: p.name.isEmpty ? 'profile' : p.name),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _Section('profile'),
          _NavTile(
            title: 'edit profile',
            subtitle: 'name, diet, allergies, calorie target, time budget, effort',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileEditorScreen(lang: lang))),
          ),
          _NavTile(
            title: 'language',
            subtitle: lang == 'en' ? 'English' : 'Deutsch',
            onTap: () => _langSheet(context, app, lang),
          ),
          const SizedBox(height: 12),
          _Section('cooking'),
          _SwitchTile(
            title: 'show variant tags',
            subtitle: 'render diet/effort chips on cards',
            value: p.showVariantTags,
            onChanged: (v) => app.updateProfile((p) => p.copyWith(showVariantTags: v)),
          ),
          _SwitchTile(
            title: 'calorie hard filter',
            subtitle: 'hide recipes outside target ± tolerance',
            value: p.calorieHardFilter,
            onChanged: (v) => app.updateProfile((p) => p.copyWith(calorieHardFilter: v)),
          ),
          _SwitchTile(
            title: 'time hard filter',
            subtitle: 'hide recipes over your time budget',
            value: p.timeHardFilter,
            onChanged: (v) => app.updateProfile((p) => p.copyWith(timeHardFilter: v)),
          ),
          const SizedBox(height: 12),
          _Section('accessibility'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('reduce motion', style: MorphFonts.serif(size: 16)),
            subtitle: Text(p.reduceMotion == null ? 'system default' : (p.reduceMotion! ? 'on' : 'off'), style: MorphFonts.mono(size: 10, color: MorphColors.inkMuted)),
            trailing: const Icon(Icons.chevron_right, color: MorphColors.inkMuted, size: 20),
            onTap: () {
              final next = p.reduceMotion == null ? true : (p.reduceMotion! ? false : null);
              app.updateProfile((p) => p.copyWith(reduceMotion: next, clearReduceMotion: next == null ? true : null));
            },
          ),
          _SwitchTile(
            title: 'visual timer alert',
            subtitle: 'flash coral/teal on timer completion (deaf/hard-of-hearing)',
            value: p.visualAlertEnabled,
            onChanged: (v) => app.updateProfile((p) => p.copyWith(visualAlertEnabled: v)),
          ),
          _SwitchTile(
            title: 'cook mode quick-tap',
            subtitle: 'single tap on step advances (300ms debounce)',
            value: p.quickNextTapEnabled,
            onChanged: (v) => app.updateProfile((p) => p.copyWith(quickNextTapEnabled: v)),
          ),
          const SizedBox(height: 12),
          _Section('data'),
          _NavTile(
            title: 'shopping insights',
            subtitle: 'variety score, top ingredients, seasonal breakdown',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShoppingInsightsScreen(lang: lang))),
          ),
          _NavTile(
            title: 'backup & restore',
            subtitle: 'export encrypted JSON / GZip; restore from file',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BackupScreen(lang: lang))),
          ),
          _NavTile(
            title: 'help center',
            subtitle: 'faq, dietary matching, troubleshooting',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FaqScreen(lang: lang))),
          ),
          const SizedBox(height: 16),
          const DashedRule(),
          const SizedBox(height: 8),
          Center(child: Text('MorphCook · v1.0.0 · offline', style: MorphFonts.mono(size: 9, color: MorphColors.inkMuted))),
          const SizedBox(height: 4),
          Center(child: Text('every body gets a full cookbook', style: MorphFonts.hand(size: 16, color: MorphColors.teal))),
        ],
      ),
    );
  }

  void _langSheet(BuildContext context, AppState app, String current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MorphColors.paper,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('language', style: MorphFonts.display(size: 22)),
              const DashedRule(),
              const SizedBox(height: 8),
              ListTile(
                title: Text('English', style: MorphFonts.serif(size: 16)),
                trailing: current == 'en' ? const Icon(Icons.check, color: MorphColors.coral) : null,
                onTap: () {
                  app.updateProfile((p) => p.copyWith(lang: 'en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Deutsch', style: MorphFonts.serif(size: 16)),
                trailing: current == 'de' ? const Icon(Icons.check, color: MorphColors.coral) : null,
                onTap: () {
                  app.updateProfile((p) => p.copyWith(lang: 'de'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(title.toUpperCase(), style: MorphFonts.label(size: 11, color: MorphColors.coral)),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _NavTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: MorphFonts.serif(size: 16)),
      subtitle: Text(subtitle, style: MorphFonts.mono(size: 10, color: MorphColors.inkMuted)),
      trailing: const Icon(Icons.chevron_right, color: MorphColors.inkMuted, size: 20),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: MorphFonts.serif(size: 16)),
      subtitle: Text(subtitle, style: MorphFonts.mono(size: 10, color: MorphColors.inkMuted)),
      value: value,
      activeTrackColor: MorphColors.teal,
      thumbColor: const WidgetStatePropertyAll(MorphColors.paper),
      trackOutlineColor: const WidgetStatePropertyAll(MorphColors.divider),
      onChanged: onChanged,
    );
  }
}

class ProfileEditorScreen extends StatefulWidget {
  final String lang;
  const ProfileEditorScreen({super.key, required this.lang});

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late TextEditingController _nameCtrl;
  late Set<String> _avoid;
  late Set<String> _avoidIngredients;
  late Set<String> _required;
  late int _calories;
  late int _maxTime;
  late int _tolerance;
  late String _effort;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _nameCtrl = TextEditingController(text: p.name);
    _avoid = Set.from(p.avoidFlags);
    _avoidIngredients = Set.from(p.avoidIngredients);
    _required = Set.from(p.requiredAttributes);
    _calories = p.calorieTarget;
    _maxTime = p.maxTimeMinutes;
    _tolerance = p.calorieTolerance;
    _effort = p.preferredEffort;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final app = context.read<AppState>();
    app.profile = app.profile.copyWith(
      name: _nameCtrl.text.trim(),
      avoidFlags: _avoid,
      avoidIngredients: _avoidIngredients,
      requiredAttributes: _required,
      calorieTarget: _calories,
      maxTimeMinutes: _maxTime,
      calorieTolerance: _tolerance,
      preferredEffort: _effort,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final compounds = app.corpus.ontology.compoundFlags.keys.toList();
    final classes = ['dairy', 'gluten', 'nuts', 'shellfish', 'fish', 'egg', 'soy', 'peanuts', 'tree-nuts', 'sesame', 'mustard', 'celery'];
    final ingredientOptions = app.corpus.ingredientTree.flatten().where((e) => e.depth <= 1).toList();
    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(
        title: 'edit profile',
        actions: [
          TextButton(onPressed: _save, child: Text('save', style: MorphFonts.mono(size: 12, color: MorphColors.coral))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text('name', style: MorphFonts.label(size: 11)),
          TextField(
            controller: _nameCtrl,
            style: MorphFonts.serif(size: 18),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.divider)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.coral, width: 2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('compound diets', style: MorphFonts.label(size: 11)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: compounds.map((c) => MorphChip(
                  label: c,
                  selected: _avoid.contains(c),
                  onTap: () => setState(() => _avoid.contains(c) ? _avoid.remove(c) : _avoid.add(c)),
                )).toList(),
          ),
          const SizedBox(height: 16),
          Text('avoid classes', style: MorphFonts.label(size: 11)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: classes.map((a) => MorphChip(
                  label: a,
                  selected: _avoid.contains(a),
                  onTap: () => setState(() => _avoid.contains(a) ? _avoid.remove(a) : _avoid.add(a)),
                )).toList(),
          ),
          const SizedBox(height: 16),
          Text('required attributes (halal/kosher compatible only — not certified)', style: MorphFonts.label(size: 11)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['halal', 'kosher'].map((a) => MorphChip(
                  label: a,
                  selected: _required.contains(a),
                  onTap: () => setState(() => _required.contains(a) ? _required.remove(a) : _required.add(a)),
                )).toList(),
          ),
          const SizedBox(height: 8),
          Text('we never claim halal- or kosher-certified. certification is a property of sourcing, not recipe text.',
              style: MorphFonts.hand(size: 14, color: MorphColors.teal)),
          const SizedBox(height: 16),
          Text('avoid specific ingredients', style: MorphFonts.label(size: 11)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _avoidIngredients.map((id) {
              final node = app.corpus.ingredientTree.find(id);
              return MorphChip(
                label: node != null ? ltr(node.name, widget.lang) : id,
                selected: true,
                onTap: () => setState(() => _avoidIngredients.remove(id)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Autocomplete<String>(
            optionsBuilder: (text) {
              if (text.text.isEmpty) return const Iterable<String>.empty();
              final q = text.text.toLowerCase();
              return ingredientOptions
                  .where((e) => ltr(e.name, widget.lang).toLowerCase().contains(q) || e.id.toLowerCase().contains(q))
                  .map((e) => e.id)
                  .take(8);
            },
            displayStringForOption: (id) {
              final node = app.corpus.ingredientTree.find(id);
              return node != null ? ltr(node.name, widget.lang) : id;
            },
            onSelected: (id) => setState(() => _avoidIngredients.add(id)),
            fieldViewBuilder: (context, controller, focus, onFieldSubmitted) => TextField(
              controller: controller,
              focusNode: focus,
              onSubmitted: (_) => onFieldSubmitted(),
              style: MorphFonts.serif(size: 16),
              decoration: const InputDecoration(
                hintText: 'type an ingredient...',
                hintStyle: TextStyle(color: MorphColors.inkMuted, fontStyle: FontStyle.italic),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.divider)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.coral, width: 2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('calorie target: $_calories kcal (tolerance ±$_tolerance)', style: MorphFonts.serif(size: 15)),
          Slider(
            value: _calories.toDouble(),
            min: 200,
            max: 1200,
            divisions: 20,
            activeColor: MorphColors.coral,
            inactiveColor: MorphColors.chipOff,
            onChanged: (v) => setState(() => _calories = v.round()),
          ),
          Slider(
            value: _tolerance.toDouble(),
            min: 50,
            max: 500,
            divisions: 9,
            activeColor: MorphColors.coralSoft,
            inactiveColor: MorphColors.chipOff,
            onChanged: (v) => setState(() => _tolerance = v.round()),
          ),
          const SizedBox(height: 12),
          Text('max time: $_maxTime min', style: MorphFonts.serif(size: 15)),
          Slider(
            value: _maxTime.toDouble(),
            min: 10,
            max: 120,
            divisions: 22,
            activeColor: MorphColors.teal,
            inactiveColor: MorphColors.chipOff,
            onChanged: (v) => setState(() => _maxTime = v.round()),
          ),
          const SizedBox(height: 12),
          Text('preferred effort', style: MorphFonts.label(size: 11)),
          Wrap(
            spacing: 8,
            children: ['easy', 'medium', 'hard'].map((e) => MorphChip(
                  label: e,
                  selected: _effort == e,
                  onTap: () => setState(() => _effort = e),
                )).toList(),
          ),
        ],
      ),
    );
  }
}
