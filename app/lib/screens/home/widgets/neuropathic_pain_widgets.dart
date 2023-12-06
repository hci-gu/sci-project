import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

class NeuroPathicPainWidgets extends ConsumerWidget {
  const NeuroPathicPainWidgets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(neuroPathicPainProvider).when(
          // data: (data) => NeuroPathicPain.empty(),
          data: (data) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data
                .map(
                  (e) => Padding(
                    padding: EdgeInsets.only(right: AppTheme.basePadding),
                    child: NeuroPathicPain(e),
                  ),
                )
                .toList(),
          ),
          error: (_, __) => Container(),
          loading: () => NeuroPathicPain.empty(),
        );
  }
}

class NeuroPathicPain extends HookConsumerWidget {
  final PainLevelEntry entry;

  const NeuroPathicPain(this.entry, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<int> painLevel = useState(entry.painLevel);

    useEffect(() {
      if (painLevel.value == entry.painLevel) {
        return null;
      }
      final timer = Timer(const Duration(milliseconds: 1250), () {
        ref
            .read(updateJournalProvider.notifier)
            .setJournalEntryValue(entry, painLevel.value);
      });

      return timer.cancel;
    }, [painLevel.value]);

    return _body([
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: AppTheme.iconForJournalType(entry.type, entry.bodyPart, 32),
          ),
          Text(
            entry.shortcutTitle(context),
            style: AppTheme.labelLarge,
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Button(
            width: 44,
            rounded: false,
            icon: Icons.remove,
            disabled: painLevel.value == 0,
            onPressed: () {
              painLevel.value--;
            },
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                painLevel.value.toString(),
                style: AppTheme.headLine2,
              ),
              const Text('/10'),
            ],
          ),
          Button(
            width: 44,
            rounded: false,
            icon: Icons.add,
            disabled: painLevel.value == 10,
            onPressed: () {
              painLevel.value++;
            },
          ),
        ],
      )
    ]);
  }

  static Widget _body(List<Widget> children) {
    return Container(
      width: 225,
      padding: AppTheme.elementPaddingSmall,
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: children,
      ),
    );
  }

  static empty() {
    return _body([
      Container(
        width: double.infinity,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Button(
              width: 44, rounded: false, icon: Icons.remove, onPressed: () {}),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '-',
                style: AppTheme.headLine2,
              ),
              const Text('/10'),
            ],
          ),
          Button(
              width: 44, rounded: false, icon: Icons.remove, onPressed: () {}),
        ],
      )
    ]);
  }
}
