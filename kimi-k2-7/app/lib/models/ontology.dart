import 'localized.dart';

class Ontology {
  final Map<String, LocalizedString> containsFlags;
  final Map<String, List<String>> compoundFlags;
  final Map<String, Map<String, LocalizedString>> attributes;
  final Set<String> allAvoidableFlags;

  Ontology({
    required this.containsFlags,
    required this.compoundFlags,
    required this.attributes,
    required this.allAvoidableFlags,
  });

  factory Ontology.fromMap(Map<String, dynamic> map) {
    final rawContains = (map['contains_flags'] as Map?)?.cast<String, dynamic>() ?? {};
    final containsFlags = rawContains.map(
      (k, v) => MapEntry(k, LocalizedString.fromMap(v)),
    );

    final rawCompound = (map['compound_flags'] as Map?)?.cast<String, dynamic>() ?? {};
    final compoundFlags = rawCompound.map(
      (k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList()),
    );

    final rawAttributes = (map['attributes'] as Map?)?.cast<String, dynamic>() ?? {};
    final attributes = <String, Map<String, LocalizedString>>{};
    for (final entry in rawAttributes.entries) {
      final innerMap = (entry.value as Map?)?.cast<String, dynamic>() ?? {};
      attributes[entry.key] = innerMap.map(
        (k, v) => MapEntry(k, LocalizedString.fromMap(v)),
      );
    }

    final avoidFlags = {
      ...containsFlags.keys,
      ...compoundFlags.keys,
    };

    return Ontology(
      containsFlags: containsFlags,
      compoundFlags: compoundFlags,
      attributes: attributes,
      allAvoidableFlags: avoidFlags,
    );
  }

  List<String> expandFlags(Iterable<String> flags) {
    final expanded = <String>{};
    for (final flag in flags) {
      if (compoundFlags.containsKey(flag)) {
        expanded.addAll(compoundFlags[flag]!);
      } else {
        expanded.add(flag);
      }
    }
    return expanded.toList();
  }

  String localizedAvoidFlag(String flag, String lang) {
    if (compoundFlags.containsKey(flag)) return flag; // TODO: localized if needed
    if (containsFlags.containsKey(flag)) {
      return containsFlags[flag]!.text(lang);
    }
    return flag;
  }

  String localizedAttribute(String category, String value, String lang) {
    final map = attributes[category];
    if (map == null || !map.containsKey(value)) return value;
    return map[value]!.text(lang);
  }
}
