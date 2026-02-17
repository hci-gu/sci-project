import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:scimovement/api/classes/counts.dart';
import 'package:scimovement/models/watch/pinetime.dart';
import 'package:scimovement/models/watch/sync_types.dart';
import 'package:scimovement/models/watch/telemetry.dart';
import 'package:scimovement/storage.dart';

typedef PineTimeProgressReporter =
    void Function(String phase, int current, int total);
typedef PineTimeUploadTelemetry =
    Future<void> Function({
      required String storedId,
      required int dataCount,
      required bool uploadSucceeded,
      required bool syncSucceeded,
      String? syncError,
      WatchTelemetry? telemetry,
      bool backgroundSync,
    });
typedef PineTimeUploadCounts =
    Future<UploadOutcome> Function(
      List<Counts> counts, {
      required bool canUploadNow,
    });
typedef PineTimeWithTimeout =
    Future<T> Function<T>(Future<T> future, Duration timeout, String code);

class PineTimeSyncCoordinator {
  final Future<void> Function() stopScan;
  final Future<bool> Function() tryLoginAndFlushPendingCounts;
  final PineTimeUploadCounts uploadCountsOrStorePending;
  final PineTimeUploadTelemetry uploadTelemetry;
  final WatchTelemetry Function() emptyTelemetry;
  final PineTimeWithTimeout withTimeout;
  final Duration bleOpTimeout;
  final Duration bleReadTimeout;

  PineTimeSyncCoordinator({
    required this.stopScan,
    required this.tryLoginAndFlushPendingCounts,
    required this.uploadCountsOrStorePending,
    required this.uploadTelemetry,
    required this.emptyTelemetry,
    required this.withTimeout,
    required this.bleOpTimeout,
    required this.bleReadTimeout,
  });

  Future<SyncOutcome> run({
    PineTimeProgressReporter? progressReporter,
    bool backgroundSync = false,
  }) async {
    final stored = Storage().getConnectedWatch();
    String? storedId;
    final WatchTelemetry attemptTelemetry = emptyTelemetry();
    bool telemetryUploadAttempted = false;
    SyncMetrics metrics = const SyncMetrics.empty();
    SyncErrorCode? syncErrorForTelemetry;
    bool syncSucceededForTelemetry = false;

    void sendProgress(String phase, int current, int total) {
      progressReporter?.call(phase, current, total);
    }

    SyncOutcome fail(SyncErrorCode error, {SyncMetrics? failureMetrics}) {
      syncErrorForTelemetry = error;
      syncSucceededForTelemetry = false;
      return SyncOutcome.failure(
        error: error,
        metrics: failureMetrics ?? metrics,
      );
    }

    try {
      if (stored == null) {
        return fail(SyncErrorCode.watchNotConfigured);
      }
      final String watchId = stored.id;
      storedId = watchId;

      sendProgress('connecting', 0, 0);
      await stopScan();

      PineTimeService.initialize(watchId);
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          await withTimeout(
            PineTimeService.instance.start(),
            const Duration(seconds: 20),
            SyncErrorCode.pinetimeConnectTimeout.code,
          );
          break;
        } catch (e) {
          if (attempt == 2) {
            rethrow;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (!PineTimeService.instance.connected) {
        debugPrint('PineTimeSyncCoordinator: connection failed');
        await _safeStopAndDispose();
        return fail(SyncErrorCode.watchConnectFailed);
      }

      final state = await withTimeout(
        PineTimeService.instance.getState(),
        bleOpTimeout,
        SyncErrorCode.pinetimeStateTimeout.code,
      );
      int totalCount = state.storedEntries;
      bool needsClear = Storage().getPineTimeNeedsClear(watchId);

      int lastIndex = Storage().getPineTimeLastIndex(watchId) ?? -1;
      int lastTimestamp = Storage().getPineTimeLastTimestamp(watchId) ?? 0;
      int startIndex = lastIndex + 1;

      if (totalCount == 0) {
        await tryLoginAndFlushPendingCounts();
        await Storage().setPineTimeNeedsClear(watchId, false);
        needsClear = false;
        await Storage().setPineTimeLastIndex(watchId, null);
        await Storage().setPineTimeLastTimestamp(watchId, null);
        sendProgress('done', 0, 0);
        await Storage().setLastSync(DateTime.now());
        syncSucceededForTelemetry = true;
        syncErrorForTelemetry = null;
        return const SyncOutcome.success(metrics: SyncMetrics.empty());
      }

      if (startIndex > totalCount) {
        await Storage().setPineTimeNeedsClear(watchId, false);
        needsClear = false;
        await Storage().setPineTimeLastIndex(watchId, null);
        await Storage().setPineTimeLastTimestamp(watchId, null);
        lastIndex = -1;
        lastTimestamp = 0;
        startIndex = 0;
      }

      final entries = await withTimeout(
        PineTimeService.instance.readAllEntries(
          startIndex: startIndex,
          onProgress: (current, total) {
            sendProgress('reading', current, total);
          },
        ),
        bleReadTimeout,
        SyncErrorCode.pinetimeReadTimeout.code,
      );
      debugPrint('PineTimeSyncCoordinator: read ${entries.length} entries');

      if (entries.isEmpty) {
        if (needsClear) {
          sendProgress('clearing', 0, 0);
          final cleared = await _clearWatchData();
          debugPrint(
            'PineTimeSyncCoordinator: pending clear retry result: $cleared',
          );
          if (!cleared) {
            return fail(
              SyncErrorCode.pinetimeClearFailed,
              failureMetrics: metrics,
            );
          }
          metrics = metrics.copyWith(watchCleared: true);
          await Storage().setPineTimeNeedsClear(watchId, false);
          needsClear = false;
          await Storage().setPineTimeLastIndex(watchId, null);
          await Storage().setPineTimeLastTimestamp(watchId, null);
        }
        await tryLoginAndFlushPendingCounts();
        sendProgress('done', 0, 0);
        await Storage().setLastSync(DateTime.now());
        syncSucceededForTelemetry = true;
        syncErrorForTelemetry = null;
        return SyncOutcome.success(metrics: metrics);
      }

      final int maxTimestamp = entries
          .map((e) => e.timestamp)
          .reduce((a, b) => a > b ? a : b);
      final int newLastIndex = startIndex + entries.length - 1;
      final filteredEntries =
          lastTimestamp > 0
              ? entries.where((e) => e.timestamp > lastTimestamp).toList()
              : entries;

      final int uniqueTimestampCount =
          filteredEntries.map((e) => e.timestamp).toSet().length;
      final bool hasDuplicateTimestamps =
          filteredEntries.length > uniqueTimestampCount;
      if (hasDuplicateTimestamps) {
        debugPrint(
          'PineTimeSyncCoordinator: duplicate timestamps '
          '(entries=${filteredEntries.length}, unique=$uniqueTimestampCount)',
        );
      }

      sendProgress('processing', 0, entries.length);
      final counts = countsFromPineTimeData(filteredEntries);
      sendProgress('uploading', 0, entries.length);
      final int dataCount = counts.length;
      if (hasDuplicateTimestamps) {
        debugPrint(
          'PineTimeSyncCoordinator: duplicate timestamps detected; '
          'continuing with deduped counts to avoid sync wedge',
        );
      }

      final bool canUploadNow = await tryLoginAndFlushPendingCounts();
      UploadOutcome uploadOutcome = const UploadOutcome.skippedNoData();

      if (counts.isNotEmpty) {
        uploadOutcome = await uploadCountsOrStorePending(
          counts,
          canUploadNow: canUploadNow,
        );
      }

      metrics = metrics.copyWith(
        dataCount: dataCount,
        uploaded: dataCount == 0 ? true : uploadOutcome.uploadedToServer,
        pendingStored: uploadOutcome.storedPending,
      );

      if (counts.isNotEmpty) {
        // Persist pending-clear state before advancing cursor so we never
        // end up in a state where cursor moved forward but clear isn't tracked.
        await Storage().setPineTimeNeedsClear(watchId, true);
        needsClear = true;
        await Storage().setPineTimeLastIndex(watchId, newLastIndex);
        await Storage().setPineTimeLastTimestamp(watchId, maxTimestamp);

        sendProgress('clearing', 0, 0);
        final cleared = await _clearWatchData();
        debugPrint('PineTimeSyncCoordinator: watch data cleared: $cleared');
        if (!cleared) {
          return fail(
            SyncErrorCode.pinetimeClearFailed,
            failureMetrics: metrics,
          );
        }

        metrics = metrics.copyWith(watchCleared: true);
        await Storage().setPineTimeNeedsClear(watchId, false);
        needsClear = false;
        await Storage().setPineTimeLastIndex(watchId, null);
        await Storage().setPineTimeLastTimestamp(watchId, null);
      } else {
        if (needsClear) {
          sendProgress('clearing', 0, 0);
          final cleared = await _clearWatchData();
          debugPrint(
            'PineTimeSyncCoordinator: pending clear during zero-count sync: '
            '$cleared',
          );
          if (!cleared) {
            return fail(
              SyncErrorCode.pinetimeClearFailed,
              failureMetrics: metrics,
            );
          }
          metrics = metrics.copyWith(watchCleared: true);
          await Storage().setPineTimeNeedsClear(watchId, false);
          await Storage().setPineTimeLastIndex(watchId, null);
          await Storage().setPineTimeLastTimestamp(watchId, null);
        }
        debugPrint(
          'PineTimeSyncCoordinator: zero counts from entries; cursor unchanged',
        );
      }

      sendProgress('done', entries.length, entries.length);
      await Storage().setLastSync(DateTime.now());
      await uploadTelemetry(
        storedId: watchId,
        dataCount: metrics.dataCount,
        uploadSucceeded: metrics.uploaded,
        syncSucceeded: true,
        syncError: null,
        telemetry: attemptTelemetry,
        backgroundSync: backgroundSync,
      );
      telemetryUploadAttempted = true;
      syncSucceededForTelemetry = true;
      syncErrorForTelemetry = null;
      debugPrint('PineTimeSyncCoordinator: sync done');
      return SyncOutcome.success(metrics: metrics);
    } catch (e, st) {
      final SyncErrorCode code;
      if (e is StateError) {
        code = syncErrorCodeFromString(e.message.toString());
      } else {
        code = SyncErrorCode.syncFailed;
      }
      syncErrorForTelemetry = code;
      syncSucceededForTelemetry = false;
      debugPrint('PineTimeSyncCoordinator failed: $e\n$st');
      return SyncOutcome.failure(error: code, metrics: metrics);
    } finally {
      try {
        if (storedId != null && !telemetryUploadAttempted) {
          final watchId = storedId;
          await uploadTelemetry(
            storedId: watchId,
            dataCount: metrics.dataCount,
            uploadSucceeded: metrics.uploaded,
            syncSucceeded: syncSucceededForTelemetry,
            syncError: syncErrorForTelemetry?.code,
            telemetry: attemptTelemetry,
            backgroundSync: backgroundSync,
          );
        }
      } catch (_) {}
      try {
        await _safeStopAndDispose();
      } catch (_) {}
    }
  }

  Future<bool> _clearWatchData() async {
    bool cleared = false;
    for (int i = 0; i < 2; i++) {
      try {
        cleared = await withTimeout(
          PineTimeService.instance.clearData(),
          const Duration(seconds: 10),
          SyncErrorCode.pinetimeClearFailed.code,
        );
      } catch (_) {
        cleared = false;
      }
      if (cleared) break;
    }
    return cleared;
  }

  Future<void> _safeStopAndDispose() async {
    try {
      await PineTimeService.instance.stopAndDispose().timeout(
        const Duration(seconds: 8),
      );
    } catch (_) {}
  }
}
