import 'localized.dart';

class Dish {
  final String id;
  final LocalizedString canonicalName;
  final LocalizedString heroText;
  final LocalizedString capCaption;
  final String stripeColor;
  final List<String> variantRecipeIds;
  final String partitionId;
  final List<String> secondaryPartitions;
  final List<String> cuisineTags;
  final String frequencyTier;

  Dish({
    required this.id,
    required this.canonicalName,
    required this.heroText,
    required this.capCaption,
    required this.stripeColor,
    required this.variantRecipeIds,
    required this.partitionId,
    required this.secondaryPartitions,
    required this.cuisineTags,
    required this.frequencyTier,
  });

  factory Dish.fromMap(Map<String, dynamic> map) {
    return Dish(
      id: map['id'] as String? ?? '',
      canonicalName: LocalizedString.fromMap(map['canonical_name']),
      heroText: LocalizedString.fromMap(map['hero_text']),
      capCaption: LocalizedString.fromMap(map['cap_caption']),
      stripeColor: map['stripe_color'] as String? ?? '#888888',
      variantRecipeIds: map.stringList('variant_recipe_ids'),
      partitionId: map['partition_id'] as String? ?? 'core',
      secondaryPartitions: map.stringList('secondary_partitions'),
      cuisineTags: map.stringList('cuisine_tags'),
      frequencyTier: map['frequency_tier'] as String? ?? 'core',
    );
  }
}
