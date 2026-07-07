import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/corpus_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_colors.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final corpus = context.read<CorpusService>();
    final lang = context.read<ProfileService>().profile.lang;
    final entries = corpus.faqList?.entries ?? [];
    final categories = entries.map((e) => e.category).toSet().toList();

    var filtered = entries.where((e) {
      final qMatch = _query.isEmpty ||
          e.question.text(lang).toLowerCase().contains(_query.toLowerCase()) ||
          e.answer.text(lang).toLowerCase().contains(_query.toLowerCase());
      final cMatch = _category == null || e.category == _category;
      return qMatch && cMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('help center')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(fontFamily: 'JetBrainsMono'),
              decoration: const InputDecoration(
                hintText: 'search FAQs',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('all'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                ...categories.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('no entries', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      return ExpansionTile(
                        title: Text(e.question.text(lang), style: Theme.of(context).textTheme.titleLarge),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(e.answer.text(lang), style: Theme.of(context).textTheme.bodyMedium),
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
