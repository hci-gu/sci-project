import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/models/watch/watch.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/widgets/button.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';
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
          Builder(
            builder: (context) {
              final lastSync = ref.watch(lastSyncProvider);
              final lastSyncValue = lastSync != null
                  ? timeago.format(lastSync)
                  : AppLocalizations.of(context)!.never;
              return Text(
                AppLocalizations.of(context)!.lastSynced(lastSyncValue),
                style: AppTheme.paragraphMedium,
              );
            },
          ),
          Text(
            AppLocalizations.of(context)!.syncInstructions,
            style: AppTheme.paragraphMedium,
          ),
          AppTheme.spacer2x,
          Button(
            onPressed: () async {
              loading.value = true;
              final result =
                  await ref.read(connectedWatchProvider.notifier).syncData();
              if (context.mounted) {
                if (result.ok) {
                  ref.read(lastSyncProvider.notifier).setLastSync(
                        DateTime.now(),
                      );
                  final hasData = (result.dataCount ?? 0) > 0;
                  final uploaded = result.uploaded != false;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hasData
                            ? (uploaded
                                ? AppLocalizations.of(context)!.syncSuccess
                                : AppLocalizations.of(context)!
                                    .syncSavedPending)
                            : AppLocalizations.of(context)!.syncNoData,
                      ),
                    ),
                  );
                } else if (result.error == kWatchNotFoundError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
                            .watchNotFoundReconnect,
                      ),
                    ),
                  );
                } else if (result.error == kWatchSyncLoginRequired) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.watchSyncLoginRequired,
                      ),
                    ),
                  );
                } else if (result.error == kBluetoothOffError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.bluetoothOffRetry,
                      ),
                    ),
                  );
                } else if (result.error == kWatchNotConfiguredError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.watchNotConfigured,
                      ),
                    ),
                  );
                } else if (result.error == kConnectionFailedError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.watchConnectFailed,
                      ),
                    ),
                  );
                } else if (result.error == kPinetimeConnectTimeout) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.pinetimeConnectTimeout,
                      ),
                    ),
                  );
                } else if (result.error == kPinetimeReadTimeout) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.pinetimeReadTimeout,
                      ),
                    ),
                  );
                } else if (result.error == kPinetimeBleError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.pinetimeBleError,
                      ),
                    ),
                  );
                } else if (result.error == kPinetimeCharacteristicMissing) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
                            .pinetimeCharacteristicMissing,
                      ),
                    ),
                  );
                } else {
                  final error = result.error?.toString();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error != null
                            ? AppLocalizations.of(context)!.syncFailed(error)
                            : AppLocalizations.of(context)!.syncNoData,
                      ),
                    ),
                  );
                }
                loading.value = false;
              }
            },
            icon: Icons.sync,
            title: AppLocalizations.of(context)!.sync,
            loading: loading.value,
          ),
        ],
      ),
    );
  }
}
