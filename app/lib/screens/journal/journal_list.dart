import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/theme/theme.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smärta'),
        actions: [
          _bodyPartFilter(ref),
        ],
      ),
      body: ref.watch(filteredJournalProvider).when(
            data: (data) => _buildList(context, data.reversed.toList(), ref),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text(e.toString()),
          ),
    );
  }

  Widget _bodyPartFilter(WidgetRef ref) {
    return ref.watch(uniqueEntriesProvider).when(
          data: (data) => PopupMenuButton<BodyPart>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              ref.read(bodyPartFilterProvider.notifier).state = filter;
            },
            onCanceled: () {
              ref.read(bodyPartFilterProvider.notifier).state = null;
            },
            itemBuilder: (context) => [
              const PopupMenuItem(child: Text('Alla'), value: null),
              ...data.map(
                (e) => PopupMenuItem(
                  child: Text(e.bodyPart.displayString()),
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
        return _listItem(context, data[index], ref);
      },
    );
  }

  Widget _listItem(BuildContext context, JournalEntry entry, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id.toString()),
      onDismissed: (direction) {
        ref.read(updateJournalProvider.notifier).deleteJournalEntry(entry.id);
      },
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showDeleteDialog(context),
      background: Container(
        color: AppTheme.colors.error,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
      ),
      child: ListTile(
        leading: BodyPartIcon(bodyPart: entry.bodyPart, size: 24),
        trailing: entry.comment.isNotEmpty ? const Icon(Icons.comment) : null,
        title: Text(
            '${entry.painLevel.toString()} - ${entry.bodyPart.displayString()}'),
        subtitle: Text(_displayTime(entry.time)),
        onTap: () => GoRouter.of(context).goNamed(
          'update-journal',
          params: {
            'id': entry.id.toString(),
          },
          extra: {
            'entry': entry,
          },
        ),
      ),
    );
  }

  String _displayTime(DateTime time) {
    time = DateTime.parse('2022-05-13T12:00:00.000Z');
    return '${DateFormat(DateFormat.HOUR24_MINUTE).format(time)}, ${DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(time)}';
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort'),
        content: const Text('Är du säker på att du vill ta bort detta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );
  }
}
