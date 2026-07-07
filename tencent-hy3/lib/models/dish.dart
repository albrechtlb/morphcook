class Dish {
  final String id;
  final Map<String, String> canonicalName;
  final Map<String, String> heroText;
  final Map<String, String> capCaption;
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

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'],
      canonicalName: Map<String, String>.from(json['canonical_name']),
      heroText: Map<String, String>.from(json['hero_text']),
      capCaption: Map<String, String>.from(json['cap_caption']),
      stripeColor: json['stripe_color'],
      variantRecipeIds: List<String>.from(json['variant_recipe_ids']),
      partitionId: json['partition_id'],
      secondaryPartitions: List<String>.from(json['secondary_partitions'] ?? []),
      cuisineTags: List<String>.from(json['cuisine_tags'] ?? []),
      frequencyTier: json['frequency_tier'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canonical_name': canonicalName,
      'hero_text': heroText,
      'cap_caption': capCaption,
      'stripe_color': stripeColor,
      'variant_recipe_ids': variantRecipeIds,
      'partition_id': partitionId,
      'secondary_partitions': secondaryPartitions,
      'cuisine_tags': cuisineTags,
      'frequency_tier': frequencyTier,
    };
  }

  String localizedName(String lang) {
    return canonicalName[lang] ?? canonicalName['en'] ?? '';
  }

  String localizedHeroText(String lang) {
    return heroText[lang] ?? heroText['en'] ?? '';
  }

  String localizedCapCaption(String lang) {
    return capCaption[lang] ?? capCaption['en'] ?? '';
  }
}
