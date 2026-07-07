import 'package:flutter/foundation.dart';

@immutable
class Profile {
  final String name;
  final String lang;
  final Set<String> avoidFlags;
  final Set<String> avoidIngredients;
  final Set<String> requiredAttributes;
  final int maxTimeMinutes;
  final int calorieTarget;
  final int calorieTolerance;
  final String preferredEffort;
  final bool showVariantTags;
  final bool? reduceMotion;
  final bool visualAlertEnabled;
  final bool quickNextTapEnabled;
  final bool calorieHardFilter;
  final bool timeHardFilter;
  final bool onboardingDone;

  const Profile({
    this.name = '',
    this.lang = 'en',
    this.avoidFlags = const {},
    this.avoidIngredients = const {},
    this.requiredAttributes = const {},
    this.maxTimeMinutes = 60,
    this.calorieTarget = 600,
    this.calorieTolerance = 200,
    this.preferredEffort = 'medium',
    this.showVariantTags = false,
    this.reduceMotion,
    this.visualAlertEnabled = true,
    this.quickNextTapEnabled = false,
    this.calorieHardFilter = true,
    this.timeHardFilter = true,
    this.onboardingDone = false,
  });

  Profile copyWith({
    String? name,
    String? lang,
    Set<String>? avoidFlags,
    Set<String>? avoidIngredients,
    Set<String>? requiredAttributes,
    int? maxTimeMinutes,
    int? calorieTarget,
    int? calorieTolerance,
    String? preferredEffort,
    bool? showVariantTags,
    bool? reduceMotion,
    bool? clearReduceMotion,
    bool? visualAlertEnabled,
    bool? quickNextTapEnabled,
    bool? calorieHardFilter,
    bool? timeHardFilter,
    bool? onboardingDone,
  }) =>
      Profile(
        name: name ?? this.name,
        lang: lang ?? this.lang,
        avoidFlags: avoidFlags ?? this.avoidFlags,
        avoidIngredients: avoidIngredients ?? this.avoidIngredients,
        requiredAttributes: requiredAttributes ?? this.requiredAttributes,
        maxTimeMinutes: maxTimeMinutes ?? this.maxTimeMinutes,
        calorieTarget: calorieTarget ?? this.calorieTarget,
        calorieTolerance: calorieTolerance ?? this.calorieTolerance,
        preferredEffort: preferredEffort ?? this.preferredEffort,
        showVariantTags: showVariantTags ?? this.showVariantTags,
        reduceMotion: clearReduceMotion == true ? null : (reduceMotion ?? this.reduceMotion),
        visualAlertEnabled: visualAlertEnabled ?? this.visualAlertEnabled,
        quickNextTapEnabled: quickNextTapEnabled ?? this.quickNextTapEnabled,
        calorieHardFilter: calorieHardFilter ?? this.calorieHardFilter,
        timeHardFilter: timeHardFilter ?? this.timeHardFilter,
        onboardingDone: onboardingDone ?? this.onboardingDone,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lang': lang,
        'avoid_flags': avoidFlags.toList(),
        'avoid_ingredients': avoidIngredients.toList(),
        'required_attributes': requiredAttributes.toList(),
        'max_time_minutes': maxTimeMinutes,
        'calorie_target': calorieTarget,
        'calorie_tolerance': calorieTolerance,
        'preferred_effort': preferredEffort,
        'show_variant_tags': showVariantTags,
        'reduce_motion': reduceMotion,
        'visual_alert_enabled': visualAlertEnabled,
        'quick_next_tap_enabled': quickNextTapEnabled,
        'calorie_hard_filter': calorieHardFilter,
        'time_hard_filter': timeHardFilter,
        'onboarding_done': onboardingDone,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] as String? ?? '',
        lang: j['lang'] as String? ?? 'en',
        avoidFlags: Set<String>.from(j['avoid_flags'] as List? ?? const []),
        avoidIngredients: Set<String>.from(j['avoid_ingredients'] as List? ?? const []),
        requiredAttributes: Set<String>.from(j['required_attributes'] as List? ?? const []),
        maxTimeMinutes: (j['max_time_minutes'] as num?)?.toInt() ?? 60,
        calorieTarget: (j['calorie_target'] as num?)?.toInt() ?? 600,
        calorieTolerance: (j['calorie_tolerance'] as num?)?.toInt() ?? 200,
        preferredEffort: j['preferred_effort'] as String? ?? 'medium',
        showVariantTags: j['show_variant_tags'] as bool? ?? false,
        reduceMotion: j['reduce_motion'] as bool?,
        visualAlertEnabled: j['visual_alert_enabled'] as bool? ?? true,
        quickNextTapEnabled: j['quick_next_tap_enabled'] as bool? ?? false,
        calorieHardFilter: j['calorie_hard_filter'] as bool? ?? true,
        timeHardFilter: j['time_hard_filter'] as bool? ?? true,
        onboardingDone: j['onboarding_done'] as bool? ?? false,
      );
}
