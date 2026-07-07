import 'localized.dart';

class IngredientNode {
  final String id;
  final LocalizedString name;
  final List<IngredientNode> children;

  IngredientNode({
    required this.id,
    required this.name,
    this.children = const [],
  });

  factory IngredientNode.fromMap(Map<String, dynamic> map) {
    return IngredientNode(
      id: map['id'] as String? ?? '',
      name: LocalizedString.fromMap((map['name'] as Map?)?.cast<String, dynamic>() ?? {}),
      children: (map['children'] as List? ?? [])
          .whereType<Map>()
          .map((e) => IngredientNode.fromMap(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  Set<String> descendantIds() {
    final ids = <String>{id};
    for (final child in children) {
      ids.addAll(child.descendantIds());
    }
    return ids;
  }

  List<IngredientNode> flatten() {
    return [this, ...children.expand((c) => c.flatten())];
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name.toMap(),
        'children': children.map((c) => c.toMap()).toList(),
      };
}

class IngredientGuideEntry {
  final String id;
  final LocalizedString name;
  final LocalizedString description;
  final LocalizedString usage;
  final LocalizedString storage;
  final LocalizedString whereToFind;

  IngredientGuideEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.usage,
    required this.storage,
    required this.whereToFind,
  });

  factory IngredientGuideEntry.fromMap(String id, Map<String, dynamic> map) {
    return IngredientGuideEntry(
      id: id,
      name: LocalizedString.fromMap(map['name']),
      description: LocalizedString.fromMap(map['description']),
      usage: LocalizedString.fromMap(map['usage']),
      storage: LocalizedString.fromMap(map['storage']),
      whereToFind: LocalizedString.fromMap(map['where_to_find']),
    );
  }
}

class AvoidanceTree {
  final IngredientNode root;

  AvoidanceTree(this.root);

  factory AvoidanceTree.fromMap(Map<String, dynamic> map) {
    return AvoidanceTree(IngredientNode.fromMap(map));
  }

  Set<String> descendantsOf(String id) {
    final node = root.flatten().firstWhere((n) => n.id == id, orElse: () => root);
    return node.descendantIds();
  }
}
