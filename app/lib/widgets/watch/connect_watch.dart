import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scimovement/ble_owner.dart';
import 'package:scimovement/foreground_service/foreground_service.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

/// Shows a dialog to select watch type (Polar or PineTime)
Future<WatchType?> showWatchTypePicker(BuildContext context) async {
  return showDialog<WatchType?>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _WatchTypePickerDialog(),
  );
}

class _WatchTypePickerDialog extends StatelessWidget {
  const _WatchTypePickerDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.selectWatchType, style: AppTheme.headLine3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _WatchTypeOption(
              title: 'Polar',
              subtitle: l10n.polarWatchDescription,
              icon: Icons.watch,
              onTap: () => Navigator.of(context).pop(WatchType.polar),
            ),
            SizedBox(height: AppTheme.basePadding),
            _WatchTypeOption(
              title: 'PineTime',
              subtitle: l10n.pineTimeWatchDescription,
              icon: Icons.watch_outlined,
              onTap: () => Navigator.of(context).pop(WatchType.pinetime),
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
        vertical: AppTheme.basePadding,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
      ),
      actionsPadding: EdgeInsets.all(AppTheme.basePadding * 2),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(null),
          secondary: true,
          rounded: true,
          size: ButtonSize.small,
          title: l10n.cancel,
        ),
      ],
    );
  }
}

class _WatchTypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _WatchTypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(AppTheme.basePadding),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: AppTheme.colors.primary),
            SizedBox(width: AppTheme.basePadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.headLine3),
                  Text(subtitle, style: AppTheme.paragraphSmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Shows device picker for the specified watch type
Future<String?> showDevicePicker(
  BuildContext context,
  WatchType watchType,
) async {
  print("showDevicePicker called for $watchType");
  if (watchType == WatchType.pinetime) {
    final ok = await _requestPineTimePermissions();
    print("ok: $ok");
    if (!ok) return null;
  } else {
    await PolarService.requestPermissions();
  }

  print("got permissons");

  if (!context.mounted) return null;

  print("show dialog");

  return showDialog<String?>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _DevicePickerDialog(watchType: watchType),
  );
}

Future<bool> _requestPineTimePermissions() async {
  if (Platform.isAndroid) {
    final sdk = _androidSdkInt();
    final osVersion = Platform.operatingSystemVersion;
    final List<Permission> permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ];
    if (sdk != null && sdk < 31) {
      permissions.add(Permission.locationWhenInUse);
    }

    final statuses = await permissions.request();
    print(
      'PineTime permissions sdk=$sdk os="$osVersion" statuses=$statuses',
    );

    final bluetoothOk =
        (statuses[Permission.bluetoothScan]?.isGranted ?? false) &&
        (statuses[Permission.bluetoothConnect]?.isGranted ?? false);
    final locationOk =
        (sdk == null || sdk >= 31) ||
        (statuses[Permission.locationWhenInUse]?.isGranted ?? false);

    return bluetoothOk && locationOk;
  }

  if (Platform.isIOS) {
    final status = await Permission.bluetooth.request();
    return status.isGranted;
  }

  return true;
}

int? _androidSdkInt() {
  if (!Platform.isAndroid) return null;
  final match = RegExp(r'SDK (\\d+)').firstMatch(
    Platform.operatingSystemVersion,
  );
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

class _DevicePickerDialog extends StatefulWidget {
  final WatchType watchType;

  const _DevicePickerDialog({required this.watchType});

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
              if (mounted) setState(() {});
            }
          } else if (event == 'done') {
            if (mounted) setState(() => _scanning = false);
          }
        }
      });

      // Pass the watch type to the scan command
      final watchTypeStr =
          widget.watchType == WatchType.pinetime ? 'pinetime' : 'polar';

      final resp = await sendBleCommand({
        'cmd': 'scan_start',
        'sink': _scanPort!.sendPort,
        'watchType': watchTypeStr,
        'autoStopMs': 10000,
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
    final l10n = AppLocalizations.of(context)!;
    final watchTypeName =
        widget.watchType == WatchType.pinetime ? 'PineTime' : 'Polar';

    return AlertDialog(
      title: Text(
        '${l10n.connectWatch} ($watchTypeName)',
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
                            ? l10n.searchingForWatches
                            : l10n.noDevicesFound,
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final d = _devices[i];
                    final selected = d["id"] == _selectedId;
                    return ListTile(
                      dense: true,
                      title: Text(d["name"] ?? l10n.unknownDevice),
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
                title: l10n.cancel,
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
                title: _scanning ? l10n.searching : l10n.searchAgain,
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
                title: l10n.connect,
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
    final l10n = AppLocalizations.of(context)!;

    if (isConnected) {
      return const SizedBox();
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Text(
            l10n.connectWatchPrompt,
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
            // Check if Bluetooth is supported
            if (await FlutterBluePlus.isSupported == false) {
              print("Bluetooth not supported by this device");
              return;
            }

            // First, show the watch type picker
            final WatchType? watchType = await showWatchTypePicker(context);
            if (watchType == null || !context.mounted) return;

            // Then show the device picker for the selected watch type
            final String? watchID = await showDevicePicker(context, watchType);

            if (watchID != null) {
              ref
                  .read(connectedWatchProvider.notifier)
                  .setConnectedWatch(
                    ConnectedWatch(id: watchID, type: watchType),
                  );
            }
          },
          icon: Icons.watch,
          title: l10n.connectWatch,
        ),
      ],
    );
  }
}
