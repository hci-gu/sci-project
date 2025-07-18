import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:timeago/timeago.dart' as timeago;

class SyncWatchData extends HookConsumerWidget {
  const SyncWatchData({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ValueNotifier<bool> loading = useState(false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Last synced: ${ref.watch(lastSyncProvider) != null ? timeago.format(ref.watch(lastSyncProvider)!) : 'Never'}',
            style: AppTheme.paragraphMedium,
          ),
          Text(
            'Press the sync button to upload your data',
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer2x,
          Button(
            onPressed: () async {
              loading.value = true;
              bool success =
                  await ref.read(connectedWatchProvider.notifier).syncData();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recordings synced successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No recordings found to sync.')),
                  );
                }
              }

              loading.value = false;
            },
            icon: Icons.sync,
            title: "Sync",
            loading: loading.value,
          ),
        ],
      ),
    );
  }
}
