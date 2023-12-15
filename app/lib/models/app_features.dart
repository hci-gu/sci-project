import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum AppFeature {
  watch,
  pressureRelease,
  pain,
  exercise,
  bladder,
}

List<AppFeature> defaultAppFeatures = [
  AppFeature.pressureRelease,
  AppFeature.pain,
  AppFeature.exercise,
  AppFeature.bladder,
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
      case AppFeature.bladder:
        return AppLocalizations.of(context)!.onboardingBladderFunctions;
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
  AppFeature.bladder: [
    JournalType.bladderEmptying,
    JournalType.leakage,
    JournalType.urinaryTractInfection
  ],
  AppFeature.exercise: [
    JournalType.exercise,
  ]
};

final appFeaturesProvider = StateProvider<List<AppFeature>>((ref) {
  ref.listenSelf((previous, next) {
    Storage().storeAppFeatures(next);
  });

  return Storage().getAppFeatures();
});
