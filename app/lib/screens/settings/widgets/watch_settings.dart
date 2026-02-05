import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
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

  const SyncProgress({this.phase = '', this.current = 0, this.total = 0});

  double get progress => total > 0 ? current / total : 0.0;
}

class DfuProgressState {
  final String phase;
  final int current;
  final int total;
  final String? message;

  const DfuProgressState({
    this.phase = '',
    this.current = 0,
    this.total = 0,
    this.message,
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
    final isUpdating = useState(false);
    final dfuProgress = useState<DfuProgressState>(const DfuProgressState());
    Future<List<dynamic>> fetchWatchState() async {
      print("Fetching watch state...");
      final stateRaw = await sendBleCommand({'cmd': 'get_state'})
          .catchError((_) => <String, dynamic>{});
      final Map<String, dynamic> state =
          (stateRaw['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      try {
        final adapterState = await FlutterBluePlus.adapterState.first;
        final bool? bluetoothEnabled =
            adapterState == BluetoothAdapterState.on
                ? true
                : adapterState == BluetoothAdapterState.off
                    ? false
                    : null;
        state['bluetoothEnabled'] = bluetoothEnabled;
      } catch (_) {}

      Map<String, dynamic> firmware = <String, dynamic>{};
      if (watch?.type == WatchType.pinetime &&
          state['connected'] == true &&
          !isSyncing.value &&
          !isUpdating.value) {
        final firmwareRaw = await sendBleCommand({'cmd': 'get_firmware_version'})
            .catchError((_) => <String, dynamic>{});
        firmware =
            (firmwareRaw['data'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
      }

      await Future.delayed(const Duration(seconds: 1));
      return [state, firmware, null];
    }

    final latestDfu = useState<Future<DfuReleaseInfo?>>(
      Api().getLatestDfuRelease(),
    );
    final refresh = useState<Future<List<dynamic>>>(Future.value([]));
    useEffect(() {
      refresh.value = fetchWatchState();
      return null;
    }, [watch?.id, watch?.type]);

    if (watch == null) {
      return Padding(
        padding: AppTheme.elementPadding,
        child: const Center(child: ConnectWatch()),
      );
    }

    Future<void> handleDfuUpdate(DfuReleaseInfo? releaseInfo) async {
      final l10n = AppLocalizations.of(context)!;
      final bool? confirmed = await confirmDialog(
        context,
        title: l10n.firmwareUpdateConfirmTitle,
        message: l10n.firmwareUpdateConfirmBody,
      );
      if (confirmed != true) return;

      isUpdating.value = true;
      dfuProgress.value = const DfuProgressState(phase: 'downloading');

      final progressPort = ReceivePort();
      progressPort.listen((msg) {
        if (msg is Map && msg['type'] == 'dfu_progress') {
          dfuProgress.value = DfuProgressState(
            phase: msg['phase'] ?? '',
            current: msg['current'] ?? 0,
            total: msg['total'] ?? 0,
            message: msg['message']?.toString(),
          );
        }
      });

      try {
        final result = await sendBleCommand({
          'cmd': 'dfu_start',
          'version': releaseInfo?.version,
          'progressSink': progressPort.sendPort,
        });
        if (context.mounted) {
          if (result['ok'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.firmwareUpdateDone),
                backgroundColor: Colors.green,
              ),
            );
            latestDfu.value = Api().getLatestDfuRelease();
            refresh.value = fetchWatchState();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.firmwareUpdateFailed(
                    result['error']?.toString() ?? l10n.genericError,
                  ),
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
              content: Text(l10n.firmwareUpdateFailed(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        progressPort.close();
        isUpdating.value = false;
        dfuProgress.value = const DfuProgressState();
      }
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
          'backgroundSync': false,
        });
        if (context.mounted) {
          if (result['ok'] == true) {
            ref.read(lastSyncProvider.notifier).setLastSync(DateTime.now());
            final int dataCount = (result['dataCount'] as int?) ?? 0;
            final bool uploaded = (result['uploaded'] as bool?) ?? true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  dataCount > 0
                      ? (uploaded
                          ? AppLocalizations.of(context)!.syncSuccess
                          : AppLocalizations.of(context)!.syncSavedPending)
                      : AppLocalizations.of(context)!.syncNoData,
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh the state after sync
            refresh.value = fetchWatchState();
          } else {
            final l10n = AppLocalizations.of(context)!;
            final error = result['error']?.toString();
            String? message;
            if (error == kPinetimeConnectTimeout) {
              message = l10n.pinetimeConnectTimeout;
            } else if (error == kPinetimeReadTimeout) {
              message = l10n.pinetimeReadTimeout;
            } else if (error == kPinetimeBleError) {
              message = l10n.pinetimeBleError;
            } else if (error == kPinetimeCharacteristicMissing) {
              message = l10n.pinetimeCharacteristicMissing;
            } else if (error == kBluetoothOffError) {
              message = l10n.bluetoothOffRetry;
            } else if (error == kWatchNotFoundError) {
              message = l10n.watchNotFoundReconnect;
            } else if (error == kWatchNotConfiguredError) {
              message = l10n.watchNotConfigured;
            } else if (error == kConnectionFailedError) {
              message = l10n.watchConnectFailed;
            } else if (error == kWatchSyncLoginRequired) {
              message = l10n.watchSyncLoginRequired;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message ?? l10n.syncFailed(error ?? 'Unknown error'),
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
            final firmwareData =
                snapshot.data?[1] as Map<dynamic, dynamic>? ?? {};
            final mergedData =
                firmwareData['firmwareVersion'] != null
                    ? {
                      ...data,
                      'firmwareVersion': firmwareData['firmwareVersion'],
                    }
                    : data;
            final isLoading =
                snapshot.connectionState != ConnectionState.done ||
                isSyncing.value;
            final firmwareVersion = mergedData['firmwareVersion']?.toString();

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
                          mergedData,
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
                            refresh.value = fetchWatchState();
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
                        disabled: isUpdating.value,
                      );
                    },
                  ),
                  AppTheme.spacer2x,
                  FutureBuilder(
                    future: latestDfu.value,
                    builder: (context, snapshot) {
                      final l10n = AppLocalizations.of(context)!;
                      final info = snapshot.data;
                      final currentVersion =
                          firmwareVersion?.trim().isNotEmpty == true &&
                                  firmwareVersion != 'unknown'
                              ? firmwareVersion!.trim()
                              : null;

                      if (isUpdating.value) {
                        return _DfuProgressIndicator(
                          progress: dfuProgress.value,
                        );
                      }

                      if (snapshot.connectionState != ConnectionState.done) {
                        return Row(
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
                              l10n.firmwareUpdateChecking,
                              style: AppTheme.paragraphSmall,
                            ),
                          ],
                        );
                      }

                      if (info == null) {
                        return Text(
                          l10n.firmwareUpdateNotAvailable,
                          style: AppTheme.paragraphSmall,
                        );
                      }

                      final latestVersion =
                          info.version.trim().isNotEmpty &&
                                  info.version != 'unknown'
                              ? info.version.trim()
                              : null;
                      final isUpdateAvailable =
                          currentVersion != null &&
                          latestVersion != null &&
                          _isNewerVersion(latestVersion, currentVersion);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.firmwareUpdateLatest(info.version),
                            style: AppTheme.paragraphSmall,
                          ),
                          if (isUpdateAvailable) ...[
                            AppTheme.spacer2x,
                            Text(
                              l10n.firmwareUpdateAvailable(
                                currentVersion!,
                                latestVersion!,
                              ),
                              style: AppTheme.paragraphSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.firmwareUpdatePrompt,
                              style: AppTheme.paragraphSmall,
                            ),
                            AppTheme.spacer2x,
                            Button(
                              onPressed: () => handleDfuUpdate(info),
                              title: l10n.firmwareUpdateButton,
                              icon: Icons.system_update,
                              loading: false,
                              disabled: isUpdating.value || isSyncing.value,
                            ),
                          ],
                        ],
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

  int _compareVersions(String a, String b) {
    final aParts =
        RegExp(
          r'\d+',
        ).allMatches(a).map((m) => int.parse(m.group(0)!)).toList();
    final bParts =
        RegExp(
          r'\d+',
        ).allMatches(b).map((m) => int.parse(m.group(0)!)).toList();

    if (aParts.isEmpty || bParts.isEmpty) {
      return a.compareTo(b);
    }

    final length =
        aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < length; i++) {
      final aValue = i < aParts.length ? aParts[i] : 0;
      final bValue = i < bParts.length ? bParts[i] : 0;
      if (aValue != bValue) {
        return aValue.compareTo(bValue);
      }
    }
    return 0;
  }

  bool _isNewerVersion(String latest, String current) {
    return _compareVersions(latest, current) > 0;
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
        return AppLocalizations.of(
          context,
        )!.syncPhaseReading(progress.current, progress.total);
      case 'uploading':
        return AppLocalizations.of(context)!.syncPhaseUploading;
      case 'processing':
        return AppLocalizations.of(context)!.syncPhaseProcessing;
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
            Text(_getPhaseText(context), style: AppTheme.paragraphSmall),
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

class _DfuProgressIndicator extends StatelessWidget {
  final DfuProgressState progress;

  const _DfuProgressIndicator({required this.progress});

  String _getPhaseText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (progress.phase) {
      case 'downloading':
        return l10n.firmwareUpdateDownloading;
      case 'preparing':
        return l10n.firmwareUpdatePreparing;
      case 'connecting':
        return l10n.firmwareUpdateConnecting;
      case 'init_packet':
        return l10n.firmwareUpdateInitPacket;
      case 'transfer':
        return l10n.firmwareUpdateTransferring;
      case 'validate':
        return l10n.firmwareUpdateValidating;
      case 'reboot':
        return l10n.firmwareUpdateRebooting;
      case 'done':
        return l10n.firmwareUpdateDone;
      default:
        return l10n.firmwareUpdateInProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showProgressBar =
        (progress.phase == 'transfer' || progress.phase == 'downloading') &&
        progress.total > 0;

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
            Text(_getPhaseText(context), style: AppTheme.paragraphSmall),
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
