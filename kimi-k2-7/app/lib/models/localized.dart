import 'dart:convert';

class LocalizedString {
  final Map<String, String> values;

  const LocalizedString(this.values);

  factory LocalizedString.fromMap(Map<String, dynamic> map) {
    return LocalizedString(
      map.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  String text(String lang) => values[lang] ?? values['en'] ?? values.values.firstOrNull ?? '';

  Map<String, dynamic> toMap() => values;

  LocalizedString copyWith(Map<String, String>? override) {
    return LocalizedString({...values, if (override != null) ...override});
  }

  @override
  String toString() => 'LocalizedString(${jsonEncode(values)})';
}

extension MapStringSet on Map<String, dynamic> {
  Set<String> stringSet(String key) {
    final value = this[key];
    if (value == null) return <String>{};
    if (value is List) return value.map((e) => e.toString()).toSet();
    return <String>{};
  }

  List<String> stringList(String key) {
    final value = this[key];
    if (value == null) return <String>[];
    if (value is List) return value.map((e) => e.toString()).toList();
    return <String>[];
  }
}
