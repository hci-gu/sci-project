import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/condition_item.dart';
import 'package:scimovement/widgets/condition_select.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

final pressureUlcerDisplayProvider =
    FutureProvider.family<ConditionDisplay, BuildContext>((ref, context) async {
  UTIEntry? entry = await ref.watch(utiProvider.future);

  String title = '';
  String subtitle = '';
  if (context.mounted) {
    title = entry?.title(context) ?? AppLocalizations.of(context)!.noUti;
    subtitle = entry != null
        ? timeago.format(entry.time)
        : AppLocalizations.of(context)!.noLoggedUti;
  }

  return ConditionDisplay(
    title: title,
    subtitle: subtitle,
    color: entry?.utiType.color(),
  );
});

class UTIWidget extends ConsumerWidget {
  const UTIWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            AppLocalizations.of(context)!.urinaryTractInfection,
            style: AppTheme.labelLarge,
            maxLines: 1,
          ),
          AppTheme.spacer,
          ConditionSelect(
            provider: pressureUlcerDisplayProvider(context),
            modal: const UTIModal(),
          ),
        ],
      ),
    );
  }
}

class UTIModal extends ConsumerWidget {
  const UTIModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.utiChangeStatus,
          style: AppTheme.paragraphSmall,
        ),
        AppTheme.separator,
        ...UTIType.values.map((type) => _listItem(context, type)).toList(),
      ],
    );
  }

  Widget _listItem(BuildContext context, UTIType type) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.pop(context);
        context.pushNamed('create-journal', extra: {
          'entry': UTIEntry(
            id: 0,
            type: JournalType.urinaryTractInfection,
            comment: '',
            time: DateTime.now(),
            utiType: type,
          ),
        });
      },
      child: ConditionItem(
        display: ConditionDisplay(
          color: type.color(),
          title: type.displayString(context),
          subtitle: type.description(context),
        ),
      ),
    );
  }
}
