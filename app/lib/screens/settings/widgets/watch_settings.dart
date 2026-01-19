import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
import 'package:scimovement/widgets/watch/connect_watch.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Progress state for PineTime sync
class SyncProgress {
  final String phase;
  final int current;
  final int total;

  const SyncProgress({
    this.phase = '',
    this.current = 0,
    this.total = 0,
  });

  double get progress => total > 0 ? current / total : 0.0;
}

class WatchSettings extends HookConsumerWidget {
  const WatchSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(connectedWatchProvider);
    final isSyncing = useState(false);
    final syncProgress = useState<SyncProgress>(const SyncProgress());
    final refresh = useState(
      Future.wait([
        sendBleCommand({'cmd': 'get_state'})
            .then((m) {
              final data = m['data'];
              if (data is Map) {
                return data;
              }
              return <String, dynamic>{};
            })
            .catchError((_) => <String, dynamic>{}),
        Future.delayed(const Duration(seconds: 1)),
      ]),
    );

    if (watch == null) {
      return Padding(
        padding: AppTheme.elementPadding,
        child: const Center(child: ConnectWatch()),
      );
    }

    Future<void> handleSync() async {
      isSyncing.value = true;
      syncProgress.value = const SyncProgress(phase: 'connecting');

      // Create a receive port for progress updates
      final progressPort = ReceivePort();

      // Listen for progress updates
      progressPort.listen((msg) {
        if (msg is Map && msg['type'] == 'sync_progress') {
          syncProgress.value = SyncProgress(
            phase: msg['phase'] ?? '',
            current: msg['current'] ?? 0,
            total: msg['total'] ?? 0,
          );
        }
      });

      try {
        final result = await sendBleCommand({
          'cmd': 'sync',
          'progressSink': progressPort.sendPort,
        });
        if (context.mounted) {
          if (result['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.syncSuccess),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh the state after sync
            refresh.value = Future.wait([
              sendBleCommand({
                'cmd': 'get_state',
              }).then((m) => m['data'] as Map? ?? {}),
              Future.delayed(const Duration(seconds: 1)),
            ]);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.syncFailed(result['error']?.toString() ?? 'Unknown error'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.syncFailed(e.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        progressPort.close();
        isSyncing.value = false;
        syncProgress.value = const SyncProgress();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        FutureBuilder(
          future: refresh.value,
          builder: (ctx, snapshot) {
            final data = snapshot.data?[0] as Map<dynamic, dynamic>? ?? {};
            final isLoading =
                snapshot.connectionState != ConnectionState.done ||
                isSyncing.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    isLoading && !isSyncing.value
                        ? _loadingRow()
                        : _watchConnectionRow(
                          ctx,
                          ref,
                          data,
                          watch,
                          isSyncing: isSyncing.value,
                        ),
                    Column(
                      children: [
                        Button(
                          onPressed: () async {
                            bool? disconnect = await confirmDialog(
                              context,
                              title:
                                  AppLocalizations.of(
                                    context,
                                  )!.confirmDisconnectWatchTitle,
                              message:
                                  AppLocalizations.of(
                                    context,
                                  )!.disconnectWatchConfirmation,
                            );
                            if (disconnect == true) {
                              ref
                                  .read(connectedWatchProvider.notifier)
                                  .removeConnectedWatch();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.watchDisconnected,
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
                          disabled: isLoading,
                        ),
                        AppTheme.spacer2x,
                        Button(
                          onPressed: () {
                            refresh.value = Future.wait([
                              sendBleCommand({
                                'cmd': 'get_state',
                              }).then((m) => m['data'] as Map? ?? {}),
                              Future.delayed(const Duration(seconds: 1)),
                            ]);
                          },
                          title: AppLocalizations.of(context)!.refresh,
                          icon: Icons.refresh,
                          width: 120,
                          secondary: true,
                          size: ButtonSize.tiny,
                          disabled: isLoading,
                        ),
                      ],
                    ),
                  ],
                ),
                if (watch.type == WatchType.pinetime) ...[
                  AppTheme.spacer2x,
                  Consumer(
                    builder: (context, ref, child) {
                      final lastSync = ref.watch(lastSyncProvider);
                      final recentlySynced =
                          lastSync != null &&
                          DateTime.now().difference(lastSync).inMinutes < 3;

                      // Show progress bar when syncing
                      if (isSyncing.value) {
                        return _SyncProgressIndicator(
                          progress: syncProgress.value,
                        );
                      }

                      if (recentlySynced) {
                        return const SizedBox.shrink();
                      }

                      return Button(
                        onPressed: handleSync,
                        title: AppLocalizations.of(context)!.sync,
                        icon: Icons.sync,
                        loading: false,
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
        AppTheme.spacer2x,
        Consumer(
          builder: (context, ref, child) {
            final lastSync = ref.watch(lastSyncProvider);
            final lastSyncValue =
                lastSync != null
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
    WidgetRef ref,
    Map<dynamic, dynamic> data,
    ConnectedWatch watch, {
    bool isSyncing = false,
  }) {
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

    // Determine status text based on watch type and connection state
    String statusText;
    if (isSyncing) {
      statusText = AppLocalizations.of(context)!.syncing;
    } else if (watch.type == WatchType.pinetime) {
      // PineTime uses manual sync - always show ready status
      statusText = AppLocalizations.of(context)!.readyToSync;
    } else if (data['isRecording'] == true) {
      statusText = AppLocalizations.of(context)!.recordingInProgress;
    } else if (data['connected'] == true) {
      statusText = AppLocalizations.of(context)!.connected;
    } else {
      statusText = AppLocalizations.of(context)!.disconnected;
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
          child:
              isSyncing
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.colors.primary,
                    ),
                  )
                  : Icon(
                    Icons.watch,
                    color:
                        data['connected'] == true ||
                                watch.type == WatchType.pinetime
                            ? AppTheme.colors.primary
                            : Colors.grey[700],
                  ),
        ),
        AppTheme.spacer2x,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                watch.type == WatchType.pinetime ? 'PineTime' : watch.id,
                style: AppTheme.paragraphMedium,
              ),
              Text(statusText, style: AppTheme.paragraphSmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget to display sync progress with a progress bar
class _SyncProgressIndicator extends StatelessWidget {
  final SyncProgress progress;

  const _SyncProgressIndicator({required this.progress});

  String _getPhaseText(BuildContext context) {
    switch (progress.phase) {
      case 'connecting':
        return AppLocalizations.of(context)!.syncPhaseConnecting;
      case 'reading':
        return AppLocalizations.of(context)!.syncPhaseReading(
          progress.current,
          progress.total,
        );
      case 'uploading':
        return AppLocalizations.of(context)!.syncPhaseUploading;
      case 'clearing':
        return AppLocalizations.of(context)!.syncPhaseClearing;
      case 'done':
        return AppLocalizations.of(context)!.syncPhaseDone;
      default:
        return AppLocalizations.of(context)!.syncing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProgressBar = progress.phase == 'reading' && progress.total > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.colors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _getPhaseText(context),
              style: AppTheme.paragraphSmall,
            ),
          ],
        ),
        if (showProgressBar) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.colors.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ],
    );
  }
}
