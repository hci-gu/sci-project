import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/widgets/button.dart';

class SyncWatchData extends HookConsumerWidget {
  final List<PolarOfflineRecordingEntry> entries;

  const SyncWatchData({super.key, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<bool> loading = useState(false);

    return Column(
      children: [
        ListView.builder(
          itemCount: entries.length,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              title: Text('Recording ${index + 1}'),
              subtitle: Text(
                'Type: ${entry.type}, Start: ${entry.date}, Size: ${entry.size}',
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  PolarService.instance.deleteRecording(entry);
                },
              ),
            );
          },
        ),
        Button(
          onPressed: () async {
            loading.value = true;
            (AccOfflineRecording?, HrOfflineRecording?) records =
                await PolarService.instance.getRecordings(entries);

            if (records.$1 != null && records.$2 != null) {
              List<Counts> counts = countsFromPolarData(
                records.$1!,
                records.$2!,
              );
              await Api().uploadCounts(counts);
            } else if (context.mounted) {
              // Handle the case where no recordings were found
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No recordings found to sync.')),
              );
            }

            loading.value = false;
          },
          title: "Sync",
          loading: loading.value,
        ),
      ],
    );
  }
}
