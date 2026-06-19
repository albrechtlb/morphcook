import 'localized.dart';

class RelatedLink {
  final LocalizedString label;
  final String route;

  RelatedLink({required this.label, required this.route});

  factory RelatedLink.fromMap(Map<String, dynamic> map) {
    return RelatedLink(
      label: LocalizedString.fromMap(map['label']),
      route: map['route'] as String? ?? '',
    );
  }
}

class FAQEntry {
  final String id;
  final String category;
  final LocalizedString question;
  final LocalizedString answer;
  final List<RelatedLink> relatedLinks;

  FAQEntry({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.relatedLinks,
  });

  factory FAQEntry.fromMap(Map<String, dynamic> map) {
    return FAQEntry(
      id: map['id'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      question: LocalizedString.fromMap(map['question']),
      answer: LocalizedString.fromMap(map['answer']),
      relatedLinks: (map['related_links'] as List? ?? [])
          .whereType<Map>()
          .map((e) => RelatedLink.fromMap(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class FAQList {
  final int schemaVersion;
  final List<FAQEntry> entries;

  FAQList({required this.schemaVersion, required this.entries});

  factory FAQList.fromMap(Map<String, dynamic> map) {
    return FAQList(
      schemaVersion: map['schema_version'] as int? ?? 1,
      entries: (map['entries'] as List? ?? [])
          .whereType<Map>()
          .map((e) => FAQEntry.fromMap(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
