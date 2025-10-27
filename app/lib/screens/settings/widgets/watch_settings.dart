import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class WatchSettings extends HookConsumerWidget {
  const WatchSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(connectedWatchProvider);
    final refresh = useState(
      Future.wait([
        sendBleCommand({'cmd': 'get_state'}).then((m) => m['data'] as Map),
        Future.delayed(const Duration(seconds: 1)),
      ]),
    );

    if (watch == null) {
      return Padding(
        padding: AppTheme.elementPadding,
        child: Center(
          child: Text(AppLocalizations.of(context)!.noWatchConnected),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FutureBuilder(
          future: refresh.value,
          builder: (ctx, snapshot) {
            final data = snapshot.data?[0] as Map<dynamic, dynamic>? ?? {};

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                snapshot.connectionState == ConnectionState.done
                    ? _watchConnectionRow(ctx, data, watch)
                    : _loadingRow(),
                Column(
                  children: [
                    Button(
                      onPressed: () async {
                        bool? disconnect = await confirmDialog(
                          context,
                          title: AppLocalizations.of(context)!
                              .confirmDisconnectWatchTitle,
                          message: AppLocalizations.of(context)!
                              .disconnectWatchConfirmation,
                        );
                        if (disconnect == true) {
                          ref
                              .read(connectedWatchProvider.notifier)
                              .removeConnectedWatch();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!
                                      .watchDisconnected,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      title: AppLocalizations.of(context)!.disconnect,
                      icon: Icons.watch_off_outlined,
                      width: 120,
                      secondary: true,
                      size: ButtonSize.tiny,
                    ),
                    AppTheme.spacer2x,
                    Button(
                      onPressed: () {
                        refresh.value = Future.wait([
                          sendBleCommand({
                            'cmd': 'get_state',
                          }).then((m) => m['data'] as Map),
                          Future.delayed(const Duration(seconds: 1)),
                        ]);
                      },
                      title: AppLocalizations.of(context)!.refresh,
                      icon: Icons.refresh,
                      width: 120,
                      secondary: true,
                      size: ButtonSize.tiny,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        AppTheme.spacer2x,
        Builder(
          builder: (context) {
            final lastSync = ref.watch(lastSyncProvider);
            final lastSyncValue = lastSync != null
                ? timeago.format(lastSync)
                : AppLocalizations.of(context)!.never;
            return Text(
              AppLocalizations.of(context)!.lastSynced(lastSyncValue),
              style: AppTheme.paragraphSmall,
            );
          },
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

  Widget _watchConnectionRow(
    BuildContext context,
    Map<dynamic, dynamic> data,
    ConnectedWatch watch,
  ) {
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
                AppLocalizations.of(context)!.bluetoothOff,
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
                data['connected'] == true
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
              data['isRecording'] == true
                  ? AppLocalizations.of(context)!.recordingInProgress
                  : data['connected'] == true
                      ? AppLocalizations.of(context)!.connected
                      : AppLocalizations.of(context)!.disconnected,
              style: AppTheme.paragraphSmall,
            ),
          ],
        ),
      ],
    );
  }
}
