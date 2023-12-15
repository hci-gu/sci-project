import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/screens/journal/widgets/entry_shortcut.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/button.dart';

class SelectJournalTypeScreen extends ConsumerWidget {
  final DateTime? initialDate;

  const SelectJournalTypeScreen({super.key, this.initialDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<AppFeature> activatedFeatures = ref.watch(appFeaturesProvider);

    return Scaffold(
      appBar: AppTheme.appBar(AppLocalizations.of(context)!.newEntry),
      body: ListView(
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.basePadding * 3,
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.basePadding * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.journalCategoriesTitle,
                  style: AppTheme.headLine3,
                ),
                Text(
                  AppLocalizations.of(context)!.journalCategoriesDescription,
                  style: AppTheme.paragraphMedium,
                ),
              ],
            ),
          ),
          AppTheme.spacer2x,
          Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedFeatures.entries
                .sorted((a, b) {
                  if (activatedFeatures.contains(a.key) &&
                      !activatedFeatures.contains(b.key)) {
                    return -1;
                  } else if (!activatedFeatures.contains(a.key) &&
                      activatedFeatures.contains(b.key)) {
                    return 1;
                  } else {
                    return 0;
                  }
                })
                .map((e) => _featureRow(context, ref, e))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(BuildContext context, WidgetRef ref,
      MapEntry<AppFeature, List<JournalType>> featureGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppTheme.basePadding * 2),
          child: Text(
            featureGroup.key.displayString(context),
            style: AppTheme.labelLarge,
          ),
        ),
        AppTheme.spacer,
        if (!ref.watch(appFeaturesProvider).contains(featureGroup.key))
          _emptyState(context),
        if (ref.watch(appFeaturesProvider).contains(featureGroup.key))
          Container(
            padding: EdgeInsets.only(bottom: AppTheme.basePadding * 2),
            height: 176,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              padding: EdgeInsets.only(left: AppTheme.basePadding * 2),
              children: featureGroup.value
                  .map((e) => _shortCutForType(context, e))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.basePadding * 2),
      child: Column(
        children: [
          const Text(
            'You have deactivated this feature, do you want to toggle it back on?',
          ),
          AppTheme.spacer,
          Button(
            onPressed: () => context.goNamed('settings'),
            title: 'Go to settings',
          ),
        ],
      ),
    );
  }

  Widget _shortCutForType(BuildContext context, JournalType type) {
    return Padding(
      padding: EdgeInsets.only(right: AppTheme.basePadding * 2),
      child: SizedBox(
        width: 160,
        height: 160,
        child: JournalEntryShortcut(
          onTap: () => _navigate(context, type),
          icon: AppTheme.iconForJournalType(type),
          title: type.displayString(context),
        ),
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
