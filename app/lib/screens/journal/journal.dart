import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/screens/journal/widgets/journal_shortcut_grid.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/button.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPadding = EdgeInsets.symmetric(
      horizontal: AppTheme.basePadding * 2,
    );

    return ListView(
      padding: EdgeInsets.symmetric(vertical: AppTheme.basePadding * 3),
      children: [
        _header(context),
        Padding(
          padding: hPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppTheme.separator,
              const JournalShortcutGrid(),
              AppTheme.spacer2x,
              _addItem(context),
              AppTheme.separator,
              _seeAll(context),
              AppTheme.separator,
            ],
          ),
        ),
      ],
    );
  }

  Widget _addItem(BuildContext context) {
    return Button(
      width: 200,
      icon: Icons.add,
      title: 'Ny loggning',
      onPressed: () => GoRouter.of(context).goNamed('select-journal-type'),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.basePadding * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loggbok',
              style: AppTheme.headLine2,
            ),
            Text(
              'Tryck på en knapp nedan för att skapa nytt inlägg inom samma kategori.',
              style: AppTheme.paragraphMedium,
            ),
          ],
        ));
  }

  Widget _seeAll(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.list),
      onTap: () => GoRouter.of(context).goNamed('journal-list'),
      title: Text(
        AppLocalizations.of(context)!.listEntries,
        style: AppTheme.labelLarge,
      ),
      subtitle: Text(AppLocalizations.of(context)!.listEntriesDescription),
      trailing: const Icon(Icons.arrow_forward_ios),
    );
  }
}
