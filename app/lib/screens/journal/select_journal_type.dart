import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/screens/journal/widgets/entry_shortcut.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectJournalTypeScreen extends ConsumerWidget {
  final DateTime? initialDate;

  const SelectJournalTypeScreen({super.key, this.initialDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppTheme.appBar(AppLocalizations.of(context)!.newEntry),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.basePadding * 3,
          vertical: AppTheme.basePadding * 3,
        ),
        children: [
          Text(
            AppLocalizations.of(context)!.journalCategoriesTitle,
            style: AppTheme.headLine3,
          ),
          Text(
            AppLocalizations.of(context)!.journalCategoriesDescription,
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer2x,
          GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.basePadding * 4,
            mainAxisSpacing: AppTheme.basePadding * 4,
            shrinkWrap: true,
            children: [
              if (ref.watch(appFeaturesProvider).contains(AppFeature.pain))
                JournalEntryShortcut(
                  onTap: () => _navigate(context, JournalType.musclePain),
                  icon: AppTheme.iconForJournalType(JournalType.musclePain),
                  title: AppLocalizations.of(context)!.musclePainTitle,
                ),
              if (ref.watch(appFeaturesProvider).contains(AppFeature.pain))
                JournalEntryShortcut(
                  onTap: () => _navigate(context, JournalType.neuropathicPain),
                  icon:
                      AppTheme.iconForJournalType(JournalType.neuropathicPain),
                  title: AppLocalizations.of(context)!.neuropathicPain,
                ),
              if (ref.watch(appFeaturesProvider).contains(AppFeature.pain))
                JournalEntryShortcut(
                  onTap: () => _navigate(context, JournalType.spasticity),
                  icon: AppTheme.iconForJournalType(JournalType.spasticity),
                  title: AppLocalizations.of(context)!.spasticity,
                ),
              if (ref
                  .watch(appFeaturesProvider)
                  .contains(AppFeature.pressureRelease))
                JournalEntryShortcut(
                  onTap: () => _navigate(context, JournalType.pressureRelease),
                  icon:
                      AppTheme.iconForJournalType(JournalType.pressureRelease),
                  title: AppLocalizations.of(context)!.pressureRelease,
                ),
              if (ref
                  .watch(appFeaturesProvider)
                  .contains(AppFeature.pressureRelease))
                JournalEntryShortcut(
                  onTap: () => _navigate(context, JournalType.pressureUlcer),
                  icon: AppTheme.iconForJournalType(JournalType.pressureUlcer),
                  title: AppLocalizations.of(context)!.pressureUlcer,
                ),
              if (ref.watch(appFeaturesProvider).contains(AppFeature.bladder))
                JournalEntryShortcut(
                  onTap: () => _navigate(context, JournalType.bladderEmptying),
                  icon:
                      AppTheme.iconForJournalType(JournalType.bladderEmptying),
                  title: AppLocalizations.of(context)!.bladderEmptying,
                ),
              if (ref.watch(appFeaturesProvider).contains(AppFeature.bladder))
                JournalEntryShortcut(
                  onTap: () =>
                      _navigate(context, JournalType.urinaryTractInfection),
                  icon: AppTheme.iconForJournalType(
                      JournalType.urinaryTractInfection),
                  title: AppLocalizations.of(context)!.urinaryTractInfection,
                ),
              if (ref.watch(appFeaturesProvider).contains(AppFeature.bladder))
                JournalEntryShortcut(
                  onTap: () => _navigate(context, JournalType.leakage),
                  icon: AppTheme.iconForJournalType(JournalType.leakage),
                  title: AppLocalizations.of(context)!.leakage,
                ),
              JournalEntryShortcut(
                onTap: () => _navigate(context, JournalType.exercise),
                icon: AppTheme.iconForJournalType(JournalType.exercise),
                title: AppLocalizations.of(context)!.exercise,
              ),
            ],
          )
        ],
      ),
    );
  }

  _navigate(BuildContext context, JournalType type) {
    GoRouter.of(context).goNamed(
      'create-journal-from-type',
      extra: {
        'type': type,
        'date': initialDate,
      },
    );
  }
}
