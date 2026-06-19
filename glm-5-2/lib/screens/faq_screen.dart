import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';

class FaqScreen extends StatefulWidget {
  final String lang;
  const FaqScreen({super.key, required this.lang});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final categories = app.corpus.faqs.map((e) => e.category).toSet().toList();
    final filtered = app.corpus.faqs.where((e) {
      if (_category != null && e.category != _category) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return ltr(e.question, widget.lang).toLowerCase().contains(q) ||
          ltr(e.answer, widget.lang).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: MorphColors.paper,
      appBar: MorphTopBar(title: 'help center', eyebrow: 'faq'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              style: MorphFonts.serif(size: 16),
              decoration: const InputDecoration(
                hintText: 'ask anything…',
                hintStyle: TextStyle(color: MorphColors.inkMuted, fontStyle: FontStyle.italic),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.divider)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MorphColors.coral, width: 2)),
                prefixIcon: Icon(Icons.search, color: MorphColors.inkMuted, size: 18),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('all', style: MorphFonts.mono(size: 10)),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                    backgroundColor: MorphColors.chipOff,
                    selectedColor: MorphColors.chipOn,
                    labelStyle: TextStyle(color: _category == null ? MorphColors.paper : MorphColors.inkSoft),
                  ),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c, style: MorphFonts.mono(size: 10)),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                        backgroundColor: MorphColors.chipOff,
                        selectedColor: MorphColors.chipOn,
                        labelStyle: TextStyle(color: _category == c ? MorphColors.paper : MorphColors.inkSoft),
                      ),
                    )),
              ],
            ),
          ),
          const DashedRule(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final e = filtered[i];
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  iconColor: MorphColors.inkMuted,
                  collapsedIconColor: MorphColors.inkMuted,
                  title: Text(ltr(e.question, widget.lang), style: MorphFonts.serif(size: 16)),
                  subtitle: Text(e.category, style: MorphFonts.mono(size: 9, color: MorphColors.inkMuted)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, right: 8),
                      child: Text(ltr(e.answer, widget.lang), style: MorphFonts.serif(size: 14, color: MorphColors.inkSoft), textAlign: TextAlign.left),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
