import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/condition_item.dart';
import 'package:scimovement/widgets/condition_select.dart';
import 'package:timeago/timeago.dart' as timeago;

final pressureUlcerDisplayProvider =
    FutureProvider.family<ConditionDisplay, BuildContext>((ref, context) async {
  List<PressureUlcerEntry> pressureUlcers =
      await ref.watch(pressureUlcerProvider.future);

  String title = pressureUlcers.isEmpty
      ? 'Inget trycksår'
      : pressureUlcers.length > 1
          ? '${pressureUlcers.length} Trycksår'
          : pressureUlcers.first.pressureUlcerType.displayString(context);
  Color color = pressureUlcers.isEmpty
      ? AppTheme.colors.white
      : pressureUlcers.length > 1
          ? AppTheme.colors.error
          : pressureUlcers.first.pressureUlcerType.color;

  return ConditionDisplay(
    title: title,
    subtitle: pressureUlcers.isEmpty
        ? null
        : timeago.format(pressureUlcers.last.time),
    color: color,
  );
});

class PressureUlcerWidget extends ConsumerWidget {
  const PressureUlcerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trycksår', style: AppTheme.labelLarge),
          AppTheme.spacer,
          ConditionSelect(
            provider: pressureUlcerDisplayProvider(context),
            modal: const PressureUlcerModal(),
          )
        ],
      ),
    );
  }
}

class PressureUlcerModal extends ConsumerWidget {
  const PressureUlcerModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(pressureUlcerProvider).when(
          data: (data) => ListView(
            children: [
              Text(
                AppLocalizations.of(context)!.pressureUlcerChangeStatus,
                style: AppTheme.labelLarge,
              ),
              AppTheme.separator,
              ...data.map((e) => _listItem(context, e)).toList(),
              AppTheme.spacer,
              Button(
                onPressed: () {
                  Navigator.pop(context);
                  context.pushNamed('create-journal', extra: {
                    'type': JournalType.pressureUlcer,
                  });
                },
                title: AppLocalizations.of(context)!.pressureUlcerAdd,
                width: 200,
              ),
              AppTheme.separator,
              _seeAllRow(context),
              AppTheme.spacer2x,
            ],
          ),
          error: (_, __) => const Text('error'),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        );
  }

  Widget _listItem(BuildContext context, PressureUlcerEntry entry) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.pop(context);
        context.pushNamed(
          'create-journal',
          extra: {
            'entry': entry,
          },
        );
      },
      child: ConditionItem(
        display: ConditionDisplay(
          color: entry.pressureUlcerType.color,
          title:
              '${entry.pressureUlcerType.displayString(context)} - ${entry.location.displayString(context)}',
          subtitle: entry.pressureUlcerType.description(context),
        ),
        button: Button(
          secondary: true,
          onPressed: () {
            Navigator.pop(context);
            context.pushNamed(
              'create-journal',
              extra: {
                'entry': entry,
              },
            );
          },
          title: AppLocalizations.of(context)!.change,
          width: 64,
          size: ButtonSize.tiny,
        ),
      ),
    );
  }

  Widget _seeAllRow(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.pop(context);
        context.goNamed('journal-list', extra: {
          'type': JournalType.pressureUlcer,
        });
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.pressureUlcerViewHistory,
                style: AppTheme.labelLarge,
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
          AppTheme.separator,
        ],
      ),
    );
  }
}
