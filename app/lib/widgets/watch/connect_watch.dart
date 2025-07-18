import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:polar/polar.dart';
import 'package:scimovement/models/watch/polar.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/widgets/confirm_dialog.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

Future<String?> connectWatchDialog(BuildContext context) {
  return showDialog<String?>(
    context: context,
    builder: (BuildContext ctx) {
      return FutureBuilder(
        future: Polar().searchForDevice().first,
        builder: (ctx, snapshot) {
          return AlertDialog(
            title: Text('Connect Watch', style: AppTheme.headLine3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.connectionState == ConnectionState.done
                      ? 'Found watch: ${snapshot.data?.name ?? 'Unknown'}'
                      : 'Searching for watch...',
                  style: AppTheme.paragraphMedium,
                ),
              ],
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
                      onPressed: () => Navigator.of(ctx).pop(null),
                      secondary: true,
                      rounded: true,
                      size: ButtonSize.small,
                      title: AppLocalizations.of(context)!.cancel,
                    ),
                  ),
                  SizedBox(width: AppTheme.basePadding * 4),
                  Expanded(
                    child: Button(
                      onPressed:
                          () => Navigator.of(ctx).pop(snapshot.data!.deviceId),
                      disabled:
                          snapshot.connectionState != ConnectionState.done ||
                          snapshot.data == null,
                      rounded: true,
                      size: ButtonSize.small,
                      color: AppTheme.colors.error,
                      title: AppLocalizations.of(context)!.yes,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

class ConnectWatch extends HookConsumerWidget {
  const ConnectWatch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchIdController = TextEditingController();
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
            String? watchID = await connectWatchDialog(context);

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
