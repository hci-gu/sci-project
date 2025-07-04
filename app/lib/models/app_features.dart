import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/storage.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

enum AppFeature {
  watch,
  pressureRelease,
  pain,
  exercise,
  bladderAndBowel,
}

List<AppFeature> defaultAppFeatures = [
  AppFeature.pressureRelease,
  AppFeature.pain,
  AppFeature.exercise,
  AppFeature.bladderAndBowel,
];

extension AppFeatureDisplayAsString on AppFeature {
  String displayString(BuildContext context) {
    switch (this) {
      case AppFeature.watch:
        return AppLocalizations.of(context)!.watchFunctions;
      case AppFeature.pressureRelease:
        return AppLocalizations.of(context)!.pressureRelease;
      case AppFeature.pain:
        return AppLocalizations.of(context)!.painAndDiscomfort;
      case AppFeature.bladderAndBowel:
        return AppLocalizations.of(context)!.onboardingBladderAndBowelFunctions;
      case AppFeature.exercise:
        return AppLocalizations.of(context)!.exercise;
    }
  }
}

final Map<AppFeature, List<JournalType>> groupedFeatures = {
  AppFeature.pain: [
    JournalType.musclePain,
    JournalType.neuropathicPain,
    JournalType.spasticity,
  ],
  AppFeature.pressureRelease: [
    JournalType.pressureRelease,
    JournalType.pressureUlcer,
  ],
  AppFeature.bladderAndBowel: [
    JournalType.bladderEmptying,
    JournalType.bowelEmptying,
    JournalType.leakage,
    JournalType.urinaryTractInfection
  ],
  AppFeature.exercise: [
    JournalType.exercise,
  ]
};

class AppFeaturesNotifier extends Notifier<List<AppFeature>> {
  @override
  List<AppFeature> build() {
    listenSelf((previous, next) {
      Storage().storeAppFeatures(next);
    });

    return Storage().getAppFeatures();
  }

  void addFeature(AppFeature feature) {
    if (state.contains(feature)) return;
    state = [...state, feature];
  }

  void removeFeature(AppFeature feature) {
    if (!state.contains(feature)) return;
    state = state.where((f) => f != feature).toList();
  }
}

final appFeaturesProvider =
    NotifierProvider<AppFeaturesNotifier, List<AppFeature>>(
  AppFeaturesNotifier.new,
);
