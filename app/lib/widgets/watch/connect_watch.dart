import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

Future<String?> showDevicePicker(BuildContext context) async {
  await sendBleCommand({'cmd': 'request_permissions'});

  if (!context.mounted) return null;

  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _DevicePickerDialog(),
  );
}

class _DevicePickerDialog extends StatefulWidget {
  const _DevicePickerDialog();

  @override
  State<_DevicePickerDialog> createState() => _DevicePickerDialogState();
}

class _DevicePickerDialogState extends State<_DevicePickerDialog> {
  final List<Map<String, String>> _devices = [];
  final Set<String> _seen = {};
  ReceivePort? _scanPort;
  StreamSubscription? _scanSub;
  bool _scanning = false;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    try {
      await _stopScan();

      setState(() {
        _devices.clear();
        _seen.clear();
        _selectedId = null;
        _scanning = true;
      });

      final unknownDeviceName =
          AppLocalizations.of(context)?.unknownDevice ?? 'Unknown';

      _scanPort = ReceivePort();
      // route raw port messages into a StreamSubscription for clean dispose
      _scanSub = _scanPort!.listen((msg) {
        if (msg is Map && msg['type'] == 'scan') {
          final event = msg['event'];
          if (event == 'device') {
            final Map<String, dynamic> dev =
                (msg['device'] as Map).cast<String, dynamic>();
            final id = dev['id'] as String;
            final name = (dev['name'] as String?) ?? unknownDeviceName;
            if (_seen.add(id)) {
              _devices.add({'id': id, 'name': name});
              if (mounted) setState(() {}); // list updated
            }
          } else if (event == 'done') {
            if (mounted) setState(() => _scanning = false);
          }
        }
      });

      // tell owner to start scanning; it will stream devices to our port
      final resp = await sendBleCommand({
        'cmd': 'scan_start',
        'sink': _scanPort!.sendPort,
        'autoStopMs': 10000, // optional auto-stop (10s) just like before
      });

      if (resp['ok'] != true) {
        setState(() => _scanning = false);
      }
    } catch (_) {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _stopScan() async {
    try {
      await sendBleCommand({'cmd': 'scan_stop'});
    } catch (_) {}
    await _scanSub?.cancel();
    _scanSub = null;
    _scanPort?.close();
    _scanPort = null;
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.connectWatch,
        style: AppTheme.headLine3,
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_devices.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.basePadding),
                child: Row(
                  children: [
                    if (_scanning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (_scanning) const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _scanning
                            ? AppLocalizations.of(context)!.searchingForWatches
                            : AppLocalizations.of(context)!.noDevicesFound,
                        style: AppTheme.paragraphMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: 1000,
                height: 200,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final d = _devices[i];
                    final selected = d["id"] == _selectedId;
                    return ListTile(
                      dense: true,
                      title: Text(
                        d["name"] ??
                            AppLocalizations.of(context)!.unknownDevice,
                      ),
                      subtitle: Text(d["id"] ?? ''),
                      trailing: selected ? const Icon(Icons.check) : null,
                      onTap: () => setState(() => _selectedId = d["id"]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      titlePadding: EdgeInsets.symmetric(
        horizontal: AppTheme.basePadding * 2,
        vertical: AppTheme.basePadding,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTheme.basePadding * 2,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      actionsPadding: EdgeInsets.all(AppTheme.basePadding * 2),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Button(
                onPressed: () => Navigator.of(context).pop(null),
                secondary: true,
                rounded: true,
                size: ButtonSize.small,
                title: AppLocalizations.of(context)!.cancel,
              ),
            ),
            SizedBox(width: AppTheme.basePadding * 2),
            Expanded(
              child: Button(
                onPressed: () {
                  if (!_scanning) _startScan();
                },
                rounded: true,
                size: ButtonSize.small,
                title:
                    _scanning
                        ? AppLocalizations.of(context)!.searching
                        : AppLocalizations.of(context)!.searchAgain,
              ),
            ),
            SizedBox(width: AppTheme.basePadding * 2),
            Expanded(
              child: Button(
                onPressed: () {
                  if (_selectedId != null) {
                    Navigator.of(context).pop(_selectedId);
                  }
                },
                disabled: _selectedId == null,
                rounded: true,
                size: ButtonSize.small,
                color: AppTheme.colors.primary,
                title: AppLocalizations.of(context)!.connect,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ConnectWatch extends HookConsumerWidget {
  const ConnectWatch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watch = ref.watch(connectedWatchProvider);
    final isConnected = watch != null;

    if (isConnected) {
      return SizedBox();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context)!.connectWatchPrompt,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        AppTheme.spacer2x,
        Button(
          onPressed: () async {
            String? watchID = await showDevicePicker(context);

            if (watchID != null) {
              ref
                  .read(connectedWatchProvider.notifier)
                  .setConnectedWatch(
                    ConnectedWatch(id: watchID, type: WatchType.polar),
                  );
            }
          },
          icon: Icons.watch,
          title: AppLocalizations.of(context)!.connectWatch,
        ),
      ],
    );
  }
}
