import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;

class WatchSettings extends ConsumerWidget {
  const WatchSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(connectedWatchProvider);

    if (watch == null) {
      return Padding(
        padding: AppTheme.elementPadding,
        child: Center(child: Text('No watch connected')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FutureBuilder(
          future: sendBleCommand({
            'cmd': 'get_state',
          }).then((m) => m['data'] as Map),
          builder: (ctx, snapshot) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                snapshot.hasData
                    ? _watchConnectionRow(snapshot.data ?? {}, watch)
                    : _loadingRow(),
                Button(
                  onPressed: () async {
                    bool? disconnect = await confirmDialog(
                      context,
                      title: 'Are you sure?',
                      message:
                          'Disconnecting your watch will stop all recordings and remove the connection. Do you want to proceed?',
                    );
                    if (disconnect == true) {
                      ref
                          .read(connectedWatchProvider.notifier)
                          .removeConnectedWatch();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Watch disconnected successfully'),
                          ),
                        );
                      }
                    }
                  },
                  title: 'Disconnect',
                  icon: Icons.watch_off_outlined,
                  width: 120,
                  secondary: true,
                  size: ButtonSize.tiny,
                ),
              ],
            );
          },
        ),
        AppTheme.spacer2x,
        Text(
          'Last synced: ${ref.watch(lastSyncProvider) != null ? timeago.format(ref.watch(lastSyncProvider)!) : 'Never'}',
          style: AppTheme.paragraphSmall,
        ),
      ],
    );
  }

  Widget _loadingRow() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: CircularProgressIndicator(color: AppTheme.colors.primary),
        ),
        AppTheme.spacer2x,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('-', style: AppTheme.paragraphMedium),
            Text('-', style: AppTheme.paragraphSmall),
          ],
        ),
      ],
    );
  }

  Widget _watchConnectionRow(Map<dynamic, dynamic> data, ConnectedWatch watch) {
    if (data['bluetoothEnabled'] == false) {
      return Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bluetooth_disabled, color: Colors.red[700]),
          ),
          AppTheme.spacer2x,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(watch.id, style: AppTheme.paragraphMedium),
              Text(
                'Bluetooth is off',
                style: AppTheme.paragraphSmall.copyWith(color: Colors.red[700]),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.watch,
            color:
                data['isRecording'] == true
                    ? AppTheme.colors.primary
                    : Colors.grey[700],
          ),
        ),
        AppTheme.spacer2x,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(watch.id, style: AppTheme.paragraphMedium),
            Text(
              data['isRecording'] == true ? 'Recording...' : 'Stopped',
              style: AppTheme.paragraphSmall,
            ),
          ],
        ),
      ],
    );
  }
}
