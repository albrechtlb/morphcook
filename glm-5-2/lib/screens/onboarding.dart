import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Onboarding: language → name → diet & allergies → calorie target + time
/// budget → confirm.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  late String _lang;
  late String _name;
  late Set<String> _avoid;
  late Set<String> _avoidIngredients;
  late Set<String> _required;
  late int _calories;
  late int _maxTime;
  late String _effort;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _lang = p.lang;
    _name = p.name;
    _avoid = Set.from(p.avoidFlags);
    _avoidIngredients = Set.from(p.avoidIngredients);
    _required = Set.from(p.requiredAttributes);
    _calories = p.calorieTarget;
    _maxTime = p.maxTimeMinutes;
    _effort = p.preferredEffort;
  }

  void _next() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _finish() {
    final app = context.read<AppState>();
    app.profile = app.profile.copyWith(
      lang: _lang,
      name: _name,
      avoidFlags: _avoid,
      avoidIngredients: _avoidIngredients,
      requiredAttributes: _required,
      calorieTarget: _calories,
      maxTimeMinutes: _maxTime,
      preferredEffort: _effort,
      onboardingDone: true,
    );
    // main.dart's Consumer<AppState> will rebuild to HomeShell automatically.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MorphColors.paper,
      body: PaperGrain(
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(child: _stepContent()),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MorphCook', style: MorphFonts.display(size: 26)),
              const Spacer(),
              Text('step ${_step + 1} / 5', style: MorphFonts.mono(size: 11, color: MorphColors.inkMuted)),
            ],
          ),
          const SizedBox(height: 8),
          const DashedRule(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed: _back,
              child: Text('back', style: MorphFonts.mono(size: 12, color: MorphColors.inkSoft)),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _next,
            style: FilledButton.styleFrom(
              backgroundColor: MorphColors.ink,
              foregroundColor: MorphColors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(_step == 4 ? 'finish' : 'next', style: MorphFonts.mono(size: 12)),
          ),
        ],
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _languageStep();
      case 1:
        return _nameStep();
      case 2:
        return _dietStep();
      case 3:
        return _caloriesTimeStep();
      case 4:
        return _confirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _languageStep() {
    return _Step(
      eyebrow: 'language',
      title: 'pick your tongue',
      hand: 'no filters here — just your kitchen, your way.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LangTile(code: 'en', label: 'English', current: _lang, onTap: () => setState(() => _lang = 'en')),
          _LangTile(code: 'de', label: 'Deutsch', current: _lang, onTap: () => setState(() => _lang = 'de')),
        ],
      ),
    );
  }

  Widget _nameStep() {
    return _Step(
      eyebrow: 'your name',
      title: 'what should we call you?',
      hand: 'just for the masthead, not for anyone else.',
      child: TextField(
        decoration: const InputDecoration(
          border: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.ink)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.coral, width: 2)),
        ),
        style: MorphFonts.serif(size: 22),
        cursorColor: MorphColors.coral,
        onChanged: (v) => _name = v,
        controller: TextEditingController(text: _name),
      ),
    );
  }

  Widget _dietStep() {
    final corpus = context.read<AppState>().corpus;
    final avoidList = ['dairy', 'gluten', 'nuts', 'shellfish', 'fish', 'egg', 'soy', 'peanuts', 'tree-nuts', 'sesame'];
    final compounds = corpus.ontology.compoundFlags.keys.toList();
    final ingredientOptions = corpus.ingredientTree.flatten().where((e) => e.depth <= 1).toList();
    return _Step(
      eyebrow: 'diet & allergies',
      title: 'how do you eat?',
      hand: 'these stay editable forever — settings → profile.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('compound diets', style: MorphFonts.label(size: 11)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: compounds.map((c) {
                final sel = _avoid.contains(c) || _required.contains(c);
                return MorphChip(
                  label: c,
                  selected: sel,
                  onTap: () => setState(() {
                    if (_avoid.contains(c)) {
                      _avoid.remove(c);
                    } else {
                      _avoid.add(c);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('avoid classes', style: MorphFonts.label(size: 11)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: avoidList.map((a) {
                final sel = _avoid.contains(a);
                return MorphChip(
                  label: a,
                  selected: sel,
                  onTap: () => setState(() => sel ? _avoid.remove(a) : _avoid.add(a)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('required attributes (e.g. halal, kosher)', style: MorphFonts.label(size: 11)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['halal', 'kosher'].map((a) {
                final sel = _required.contains(a);
                return MorphChip(
                  label: a,
                  selected: sel,
                  onTap: () => setState(() => sel ? _required.remove(a) : _required.add(a)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('avoid specific ingredients', style: MorphFonts.label(size: 11)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._avoidIngredients.map((id) {
                  final node = corpus.ingredientTree.find(id);
                  return MorphChip(
                    label: node != null ? ltr(node.name, _lang) : id,
                    selected: true,
                    onTap: () => setState(() => _avoidIngredients.remove(id)),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (text) {
                if (text.text.isEmpty) return const Iterable<String>.empty();
                final q = text.text.toLowerCase();
                return ingredientOptions
                    .where((e) => ltr(e.name, _lang).toLowerCase().contains(q) || e.id.toLowerCase().contains(q))
                    .map((e) => e.id)
                    .take(8);
              },
              displayStringForOption: (id) {
                final node = corpus.ingredientTree.find(id);
                return node != null ? ltr(node.name, _lang) : id;
              },
              onSelected: (id) => setState(() => _avoidIngredients.add(id)),
              fieldViewBuilder: (context, controller, focus, onFieldSubmitted) {
                return TextField(
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _caloriesTimeStep() {
    return _Step(
      eyebrow: 'calories & time',
      title: 'how much, how long?',
      hand: 'these preselect — they never lock you in.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('calorie target per meal: $_calories kcal', style: MorphFonts.serif(size: 16)),
          Slider(
            value: _calories.toDouble(),
            min: 200,
            max: 1200,
            divisions: 20,
            activeColor: MorphColors.coral,
            inactiveColor: MorphColors.chipOff,
            onChanged: (v) => setState(() => _calories = v.round()),
          ),
          const SizedBox(height: 16),
          Text('max time: $_maxTime minutes', style: MorphFonts.serif(size: 16)),
          Slider(
            value: _maxTime.toDouble(),
            min: 10,
            max: 120,
            divisions: 22,
            activeColor: MorphColors.teal,
            inactiveColor: MorphColors.chipOff,
            onChanged: (v) => setState(() => _maxTime = v.round()),
          ),
          const SizedBox(height: 16),
          Text('preferred effort', style: MorphFonts.label(size: 11)),
          Wrap(
            spacing: 8,
            children: ['easy', 'medium', 'hard'].map((e) {
              return MorphChip(
                label: e,
                selected: _effort == e,
                onTap: () => setState(() => _effort = e),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _confirmStep() {
    final p = context.read<AppState>().profile;
    return _Step(
      eyebrow: 'almost there',
      title: 'looks right?',
      hand: 'you can change everything later.',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row('name', _name.isEmpty ? '—' : _name),
            _Row('language', _lang),
            _Row('diet', _avoid.isEmpty ? 'classic (no avoids)' : _avoid.join(', ')),
            _Row('required', _required.isEmpty ? '—' : _required.join(', ')),
            _Row('avoid ingredients', _avoidIngredients.isEmpty ? '—' : _avoidIngredients.join(', ')),
            _Row('calorie target', '$_calories kcal ±${p.calorieTolerance}'),
            _Row('max time', '$_maxTime min'),
            _Row('preferred effort', _effort),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String hand;
  final Widget child;
  const _Step({required this.eyebrow, required this.title, required this.hand, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(), style: MorphFonts.label(size: 11, color: MorphColors.coral)),
          const SizedBox(height: 4),
          Text(title, style: MorphFonts.display(size: 28)),
          const SizedBox(height: 6),
          Text(hand, style: MorphFonts.hand(size: 20, color: MorphColors.teal)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String code;
  final String label;
  final String current;
  final VoidCallback onTap;
  const _LangTile({required this.code, required this.label, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = current == code;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: sel ? MorphColors.ink : MorphColors.divider, width: sel ? 2 : 1),
          color: sel ? MorphColors.paperDeep : MorphColors.paper,
        ),
        child: Row(
          children: [
            Text(label, style: MorphFonts.serif(size: 20, color: sel ? MorphColors.ink : MorphColors.inkSoft)),
            const Spacer(),
            if (sel) const Icon(Icons.check, color: MorphColors.coral, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String k;
  final String v;
  const _Row(this.k, this.v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(k, style: MorphFonts.mono(size: 11, color: MorphColors.inkMuted))),
          Expanded(child: Text(v, style: MorphFonts.serif(size: 16))),
        ],
      ),
    );
  }
}
