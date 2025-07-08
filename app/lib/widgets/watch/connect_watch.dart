import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/app_features.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';

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
          onPressed: () {
            ref.read(connectedWatchProvider.notifier).setConnectedWatch(
                  ConnectedWatch(
                    id: "00B94D3C",
                    type: WatchType.polar,
                  ),
                );
          },
          icon: Icons.watch,
          title: 'Connect Watch',
        ),
      ],
    );
  }
}
