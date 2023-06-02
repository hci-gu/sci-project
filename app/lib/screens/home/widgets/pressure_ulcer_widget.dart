import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class PressureUlcerDisplay {
  final String title;
  final String? subtitle;
  final Color color;

  const PressureUlcerDisplay({
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

PressureUlcerDisplay fromEntries(
    BuildContext context, List<PressureUlcerEntry> pressureUlcers) {
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

  return PressureUlcerDisplay(
    title: title,
    subtitle: pressureUlcers.isEmpty
        ? null
        : timeago.format(pressureUlcers.last.time),
    color: color,
  );
}

class PressureUlcerWidget extends ConsumerWidget {
  const PressureUlcerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(pressureUlcerProvider).when(
          data: (data) => GestureDetector(
            onTap: () {
              _openModal(context, data);
            },
            child: _body(
              _row(context, data),
            ),
          ),
          error: (_, __) => _body(const Text('error')),
          loading: () => _body(
            const Center(child: CircularProgressIndicator()),
          ),
        );
  }

  Widget _row(BuildContext context, List<PressureUlcerEntry> pressureUlcers) {
    PressureUlcerDisplay display = fromEntries(context, pressureUlcers);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: display.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AppTheme.spacerHalf,
                  Text(
                    display.title,
                    style: AppTheme.labelLarge,
                  ),
                ],
              ),
              if (display.subtitle != null)
                Expanded(
                  child: AutoSizeText(
                    display.subtitle!,
                    style: AppTheme.paragraphSmall,
                    maxLines: 2,
                  ),
                ),
            ],
          ),
        ),
        const Icon(Icons.edit_outlined)
      ],
    );
  }

  Widget _body(Widget child) {
    return AspectRatio(
      aspectRatio: 3,
      child: Container(
        decoration: AppTheme.widgetDecoration.copyWith(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: child,
      ),
    );
  }

  void _openModal(
      BuildContext context, List<PressureUlcerEntry> pressureUlcers) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      builder: (context) => Padding(
        padding: AppTheme.elementPadding,
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.pressureUlcerChangeStatus,
              style: AppTheme.labelLarge,
            ),
            AppTheme.separator,
            ...pressureUlcers
                .map((e) => PressureUlcerModalItem(entry: e))
                .toList(),
            AppTheme.spacer,
            Button(
              onPressed: () {
                Navigator.pop(context);
                context.goNamed('create-journal', extra: {
                  'type': JournalType.pressureUlcer,
                });
              },
              title: AppLocalizations.of(context)!.pressuerUlcerAdd,
              width: 200,
            ),
            AppTheme.separator,
            _seeAllRow(context),
          ],
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
                AppLocalizations.of(context)!.pressuerUlcerViewHistory,
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

class PressureUlcerModalItem extends StatelessWidget {
  final PressureUlcerEntry entry;

  const PressureUlcerModalItem({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.pop(context);
        context.goNamed(
          'create-journal',
          extra: {
            'entry': entry,
          },
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: entry.pressureUlcerType.color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.colors.black.withOpacity(0.1)),
                          ),
                        ),
                        AppTheme.spacer,
                        Text(
                          '${entry.pressureUlcerType.displayString(context)} - ${entry.bodyPart.displayString(context)}',
                          style: AppTheme.labelLarge,
                        ),
                      ],
                    ),
                    AppTheme.spacer,
                    Text(
                      entry.pressureUlcerType.description(context),
                      style: AppTheme.paragraphMedium,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Button(
                secondary: true,
                onPressed: () {
                  Navigator.pop(context);
                  context.goNamed(
                    'create-journal',
                    extra: {
                      'entry': entry,
                    },
                  );
                },
                title: AppLocalizations.of(context)!.change,
                width: 64,
                size: ButtonSize.tiny,
              )
            ],
          ),
          AppTheme.separator,
        ],
      ),
    );
  }
}
