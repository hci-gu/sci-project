import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:scimovement/widgets/editable_list_item.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loggbok'),
        actions: [
          _bodyPartFilter(ref, Pagination(page: 0, mode: ChartMode.month)),
        ],
      ),
      body: ref
          .watch(filteredJournalProvider(
              Pagination(page: 0, mode: ChartMode.month)))
          .when(
            data: (data) => _buildList(context, data.reversed.toList(), ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text(e.toString()),
          ),
    );
  }

  Widget _bodyPartFilter(WidgetRef ref, Pagination pagination) {
    return ref.watch(uniqueEntriesProvider(pagination)).when(
          data: (data) => PopupMenuButton<BodyPart>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              ref.read(bodyPartFilterProvider.notifier).state = filter;
            },
            onCanceled: () {
              ref.read(bodyPartFilterProvider.notifier).state = null;
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  child: Text(AppLocalizations.of(context)!.all), value: null),
              ...data.whereType<PainLevelEntry>().map(
                    (e) => PopupMenuItem(
                      child: Text(e.bodyPart.displayString(context)),
                      value: e.bodyPart,
                    ),
                  ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text(
            e.toString(),
          ),
        );
  }

  Widget _buildList(
      BuildContext context, List<JournalEntry> data, WidgetRef ref) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        return EditableListItem(
          id: data[index].id.toString(),
          key: Key(data[index].id.toString()),
          title: data[index].title(context),
          subtitle: _displayTime(data[index].time),
          onDismissed: () => ref
              .read(updateJournalProvider.notifier)
              .deleteJournalEntry(data[index].id),
          onTap: () => GoRouter.of(context).goNamed(
            'update-journal',
            pathParameters: {
              'id': data[index].id.toString(),
            },
            extra: {
              'entry': data[index],
            },
          ),
        );
      },
    );
  }

  String _displayTime(DateTime time) {
    return '${DateFormat(DateFormat.HOUR24_MINUTE).format(time)}, ${DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(time)}';
  }
}