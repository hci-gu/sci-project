import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

Future<String?> showDevicePicker(BuildContext context) async {
  await Polar().requestPermissions();

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
  final List<PolarDeviceInfo> _devices = [];
  StreamSubscription<PolarDeviceInfo>? _sub;
  bool _scanning = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() {
    print("start scan");
    try {
      _sub?.cancel();
      setState(() {
        _devices.clear();
        _selectedId = null;
        _scanning = true;
      });

      _sub = Polar()
          .searchForDevice()
          .where((d) {
            final idx = _devices.indexWhere((x) => x.deviceId == d.deviceId);
            final isNew = idx == -1;
            if (isNew) _devices.add(d);
            return isNew;
          })
          .listen(
            (_) => setState(() {}), // list updated
            onError: (e) => setState(() => _scanning = false),
            onDone: () => setState(() => _scanning = false),
          );

      // Optional: auto-stop after 10s
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _scanning) {
          _sub?.cancel();
          setState(() => _scanning = false);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Connect Watch', style: AppTheme.headLine3),
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
                            ? 'Searching for watches...'
                            : 'No devices found.',
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
                    final selected = d.deviceId == _selectedId;
                    return ListTile(
                      dense: true,
                      title: Text(d.name),
                      subtitle: Text(d.deviceId),
                      trailing: selected ? const Icon(Icons.check) : null,
                      onTap: () => setState(() => _selectedId = d.deviceId),
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
                title: _scanning ? 'Searching...' : 'Search again',
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
                title: 'Connect',
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
            'Connect your watch to get started!',
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
          title: 'Connect Watch',
        ),
      ],
    );
  }
}
