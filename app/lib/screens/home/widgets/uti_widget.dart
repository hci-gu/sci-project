import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/condition_item.dart';
import 'package:scimovement/widgets/condition_select.dart';
import 'package:timeago/timeago.dart' as timeago;

final pressureUlcerDisplayProvider =
    FutureProvider.family<ConditionDisplay, BuildContext>((ref, context) async {
  UTIEntry? entry = await ref.watch(utiProvider.future);

  String title = entry?.title(context) ?? 'Ingen UVI';

  return ConditionDisplay(
    title: title,
    subtitle: entry != null ? timeago.format(entry.time) : 'ingen loggad UVI',
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
          Text('Urinvägsinfektion', style: AppTheme.labelLarge),
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
          'Ändra status på urinvägsinfektion',
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
