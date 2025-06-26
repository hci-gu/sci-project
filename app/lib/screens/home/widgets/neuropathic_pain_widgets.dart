import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/api/classes/journal/spasticity.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class NeuroPathicPainWidgets extends HookConsumerWidget {
  const NeuroPathicPainWidgets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<List<JournalEntry>> cachedResponse = useState([]);
    final fetch = ref.watch(neuroPathicPainAndSpasticityProvider);

    useEffect(() {
      cachedResponse.value = fetch.value ?? [];

      return () {};
    }, [fetch]);

    return fetch.when(
      data: (data) => data.isEmpty ? _emptyState(context) : _body(data),
      error: (_, __) => Container(),
      loading: () => cachedResponse.value.isNotEmpty
          ? _body(cachedResponse.value)
          : NeuroPathicPain.empty(),
    );
  }

  Widget _body(List<JournalEntry> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: data
          .map(
            (e) => Padding(
              padding: EdgeInsets.only(right: AppTheme.basePadding),
              child: NeuroPathicPain(e),
            ),
          )
          .toList(),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Text(
            AppLocalizations.of(context)!.painAndDiscormfortEmpty,
            style: AppTheme.paragraphMedium,
          ),
        ),
        AppTheme.spacer,
        Button(
          onPressed: () => context.goNamed('select-journal-type'),
          title: AppLocalizations.of(context)!.painAndDiscormfortEmptyButton,
        )
      ],
    );
  }
}

class NeuroPathicPain extends HookConsumerWidget {
  final JournalEntry entry;

  const NeuroPathicPain(this.entry, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<int> level = useState(_valueForEntry);

    useEffect(() {
      if (level.value == _valueForEntry) {
        return null;
      }
      final timer = Timer(const Duration(milliseconds: 1250), () {
        ref
            .read(updateJournalProvider.notifier)
            .setJournalEntryValue(entry, level.value);
      });

      return timer.cancel;
    }, [level.value]);

    return _body([
      Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: AppTheme.iconForJournalType(
                entry.type,
                entry is PainLevelEntry
                    ? (entry as PainLevelEntry).bodyPart
                    : null,
                32),
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
            disabled: level.value == 0,
            onPressed: () {
              level.value--;
            },
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                level.value.toString(),
                style: AppTheme.headLine2,
              ),
              const Text('/10'),
            ],
          ),
          Button(
            width: 44,
            rounded: false,
            icon: Icons.add,
            disabled: level.value == 10,
            onPressed: () {
              level.value++;
            },
          ),
        ],
      )
    ]);
  }

  int get _valueForEntry {
    if (entry is PainLevelEntry) {
      return (entry as PainLevelEntry).painLevel;
    }
    if (entry is SpasticityEntry) {
      return (entry as SpasticityEntry).level;
    }
    return 0;
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
