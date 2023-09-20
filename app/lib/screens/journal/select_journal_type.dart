import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/screens/journal/widgets/entry_shortcut.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectJournalTypeScreen extends StatelessWidget {
  final DateTime? initialDate;

  const SelectJournalTypeScreen({super.key, this.initialDate});

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
                onTap: () => _navigate(context, JournalType.pain),
                icon: BodyPartIcon(
                  bodyPart: BodyPart(BodyPartType.scapula, null),
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.musclePainTitle,
              ),
              JournalEntryShortcut(
                onTap: () => _navigate(context, JournalType.pressureRelease),
                icon: const Icon(
                  Icons.access_alarm,
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.pressureRelease,
              ),
              JournalEntryShortcut(
                onTap: () => _navigate(context, JournalType.pressureUlcer),
                icon: const Icon(
                  Icons.album_outlined,
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.pressureUlcer,
              ),
              JournalEntryShortcut(
                onTap: () => _navigate(context, JournalType.bladderEmptying),
                icon: SvgPicture.asset('assets/svg/toilet.svg', height: 48),
                title: AppLocalizations.of(context)!.bladderEmptying,
              ),
              JournalEntryShortcut(
                onTap: () =>
                    _navigate(context, JournalType.urinaryTractInfection),
                icon: const Icon(
                  Icons.water,
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.urinaryTractInfection,
              ),
              JournalEntryShortcut(
                onTap: () => _navigate(context, JournalType.leakage),
                icon: const Icon(
                  Icons.water_drop_outlined,
                  size: 48,
                ),
                title: AppLocalizations.of(context)!.leakage,
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
