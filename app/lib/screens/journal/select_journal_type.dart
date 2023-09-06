import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/journal/widgets/entry_shortcut.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectJournalTypeScreen extends StatelessWidget {
  const SelectJournalTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              JournalEntryShortcut(
                onTap: () => GoRouter.of(context).goNamed(
                  'create-journal-from-type',
                  extra: {
                    'type': JournalType.pain,
                  },
                ),
                icon: BodyPartIcon(
                  bodyPart: BodyPart(BodyPartType.scapula, null),
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.musclePainTitle,
              ),
              JournalEntryShortcut(
                onTap: () => GoRouter.of(context).goNamed(
                  'create-journal-from-type',
                  extra: {
                    'type': JournalType.pressureRelease,
                  },
                ),
                icon: const Icon(
                  Icons.access_alarm,
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.pressureRelease,
              ),
              JournalEntryShortcut(
                onTap: () => GoRouter.of(context).goNamed(
                  'create-journal-from-type',
                  extra: {
                    'type': JournalType.pressureUlcer,
                  },
                ),
                icon: const Icon(
                  Icons.album_outlined,
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.pressureUlcer,
              ),
            ],
          )
        ],
      ),
    );
  }
}
