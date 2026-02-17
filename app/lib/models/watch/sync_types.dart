enum SyncErrorCode {
  watchNotConfigured('watch_not_configured'),
  watchNotFound('watch_not_found'),
  bluetoothOff('bluetooth_off'),
  watchConnectFailed('watch_connect_failed'),
  watchSyncLoginRequired('watch_sync_login_required'),
  syncSkippedDfuInProgress('sync_skipped_dfu_in_progress'),
  syncSkippedSyncInProgress('sync_skipped_sync_in_progress'),
  pinetimeConnectTimeout('pinetime_connect_timeout'),
  pinetimeReadTimeout('pinetime_read_timeout'),
  pinetimeBleError('pinetime_ble_error'),
  pinetimeCharacteristicMissing('pinetime_characteristic_missing'),
  pinetimeStateTimeout('pinetime_state_timeout'),
  pinetimeClearFailed('pinetime_clear_failed'),
  pinetimeDuplicateEntriesDetected('pinetime_duplicate_entries_detected'),
  syncFailed('sync_failed'),
  syncTimeout('sync_timeout');

  const SyncErrorCode(this.code);
  final String code;
}

SyncErrorCode syncErrorCodeFromString(String value) {
  for (final code in SyncErrorCode.values) {
    if (code.code == value) {
      return code;
    }
  }
  return SyncErrorCode.syncFailed;
}

enum UploadDisposition { skippedNoData, uploadedToServer, storedPending }

class UploadOutcome {
  final UploadDisposition disposition;

  const UploadOutcome._(this.disposition);

  const UploadOutcome.skippedNoData() : this._(UploadDisposition.skippedNoData);

  const UploadOutcome.uploadedToServer()
    : this._(UploadDisposition.uploadedToServer);

  const UploadOutcome.storedPending() : this._(UploadDisposition.storedPending);

  bool get uploadedToServer =>
      disposition == UploadDisposition.uploadedToServer;

  bool get storedPending => disposition == UploadDisposition.storedPending;
}

class SyncMetrics {
  final int dataCount;
  final bool uploaded;
  final bool pendingStored;
  final bool watchCleared;

  const SyncMetrics({
    required this.dataCount,
    required this.uploaded,
    required this.pendingStored,
    required this.watchCleared,
  });

  const SyncMetrics.empty()
    : dataCount = 0,
      uploaded = true,
      pendingStored = false,
      watchCleared = false;

  SyncMetrics copyWith({
    int? dataCount,
    bool? uploaded,
    bool? pendingStored,
    bool? watchCleared,
  }) {
    return SyncMetrics(
      dataCount: dataCount ?? this.dataCount,
      uploaded: uploaded ?? this.uploaded,
      pendingStored: pendingStored ?? this.pendingStored,
      watchCleared: watchCleared ?? this.watchCleared,
    );
  }
}

class SyncOutcome {
  final bool ok;
  final SyncErrorCode? error;
  final SyncMetrics metrics;

  const SyncOutcome._({
    required this.ok,
    required this.error,
    required this.metrics,
  });

  const SyncOutcome.success({required SyncMetrics metrics})
    : this._(ok: true, error: null, metrics: metrics);

  const SyncOutcome.failure({
    required SyncErrorCode error,
    SyncMetrics metrics = const SyncMetrics.empty(),
  }) : this._(ok: false, error: error, metrics: metrics);

  Map<String, dynamic> toPayload() {
    if (!ok) {
      return {
        'ok': false,
        'error': error?.code ?? SyncErrorCode.syncFailed.code,
      };
    }
    return {
      'ok': true,
      'dataCount': metrics.dataCount,
      'uploaded': metrics.uploaded,
    };
  }
}
