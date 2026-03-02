import 'dart:async';
import 'dart:typed_data';

import 'package:scimovement/models/watch/dfu/dfu_constants.dart';
import 'package:scimovement/models/watch/dfu/dfu_package.dart';
import 'package:scimovement/models/watch/dfu/dfu_progress.dart';
import 'package:scimovement/models/watch/dfu/dfu_transport.dart';

class DfuCancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw StateError('dfu_cancelled');
    }
  }
}

typedef DfuProgressCallback = void Function(DfuProgress progress);

class LegacyDfuController {
  final DfuTransport transport;
  final DfuCancelToken cancelToken;
  final int chunkSize;
  final int prn;
  final Duration timeout;

  LegacyDfuController({
    required this.transport,
    required this.cancelToken,
    this.chunkSize = kDfuDefaultChunkSize,
    this.prn = kDfuDefaultPrn,
    this.timeout = const Duration(seconds: 10),
  });

  Future<void> run(
    DfuPackage package, {
    DfuProgressCallback? onProgress,
  }) async {
    cancelToken.throwIfCancelled();

    onProgress?.call(const DfuProgress(phase: 'connecting'));
    await transport.initialize();
    await transport.requestMtu(247);

    cancelToken.throwIfCancelled();
    onProgress?.call(const DfuProgress(phase: 'preparing'));

    await _awaitResponseAfter(kDfuOpStartDfu, () async {
      await _startDfu();
      await _sendImageSize(package.imageSize);
    });

    cancelToken.throwIfCancelled();
    onProgress?.call(const DfuProgress(phase: 'init_packet'));

    await _awaitResponseAfter(
      kDfuOpInitPacket,
      () => _sendInitPacket(package.datBytes),
    );

    cancelToken.throwIfCancelled();
    onProgress?.call(
      DfuProgress(
        phase: 'transfer',
        current: 0,
        total: package.binBytes.length,
      ),
    );

    await _setPrn(prn);
    try {
      await _awaitResponseAfter(
        kDfuOpReceiveFirmware,
        () => _sendFirmware(package.binBytes, onProgress: onProgress),
      );
    } on TimeoutException catch (e) {
      if (!_isResponseTimeoutForOp(e, kDfuOpReceiveFirmware)) {
        rethrow;
      }
      // Some legacy bootloaders occasionally miss the final op_3 response
      // despite having received all firmware packets. Proceed to validate;
      // validation will still fail if image transfer was incomplete/corrupt.
    }

    cancelToken.throwIfCancelled();
    onProgress?.call(const DfuProgress(phase: 'validate'));

    try {
      await _awaitResponseAfter(kDfuOpValidate, _validate);
    } on TimeoutException catch (e) {
      if (!_isResponseTimeoutForOp(e, kDfuOpValidate)) {
        rethrow;
      }
      // Some legacy bootloaders do not emit a final op_4 response even when
      // validation succeeds. Continue with activate/reset as a best effort.
    }

    cancelToken.throwIfCancelled();
    onProgress?.call(const DfuProgress(phase: 'reboot'));

    await _activateAndReset();
    onProgress?.call(const DfuProgress(phase: 'done'));
  }

  Future<void> _startDfu() async {
    await transport.writeControlPoint([
      kDfuOpStartDfu,
      kDfuImageTypeApplication,
    ]);
  }

  Future<void> _sendImageSize(int imageSize) async {
    final bytes = ByteData(12);
    bytes.setUint32(8, imageSize, Endian.little);
    await transport.writePacket(
      bytes.buffer.asUint8List(),
      preferWriteWithoutResponse: false,
    );
  }

  Future<void> _sendInitPacket(Uint8List datBytes) async {
    await transport.writeControlPoint([kDfuOpInitPacket, 0x00]);
    await _sendInChunks(datBytes);
    await transport.writeControlPoint([kDfuOpInitPacket, 0x01]);
  }

  Future<void> _setPrn(int prn) async {
    final clamped = prn.clamp(0, 255).toInt();
    await transport.writeControlPoint([kDfuOpPacketReceiptNotifReq, clamped]);
  }

  Future<void> _sendFirmware(
    Uint8List binBytes, {
    DfuProgressCallback? onProgress,
  }) async {
    await transport.writeControlPoint([kDfuOpReceiveFirmware]);

    int sent = 0;
    int packetsSent = 0;

    while (sent < binBytes.length) {
      cancelToken.throwIfCancelled();

      final next =
          (sent + chunkSize) > binBytes.length
              ? binBytes.length
              : sent + chunkSize;
      final chunk = binBytes.sublist(sent, next);
      await transport.writePacket(chunk);
      sent = next;
      packetsSent += 1;

      if (prn > 0 && packetsSent % prn == 0) {
        final offset = await _awaitPacketReceipt();
        if (offset != sent) {
          throw StateError('dfu_offset_mismatch');
        }
      }

      onProgress?.call(
        DfuProgress(phase: 'transfer', current: sent, total: binBytes.length),
      );
    }
  }

  Future<void> _sendInChunks(Uint8List bytes) async {
    int sent = 0;
    while (sent < bytes.length) {
      cancelToken.throwIfCancelled();
      final next =
          (sent + chunkSize) > bytes.length ? bytes.length : sent + chunkSize;
      await transport.writePacket(
        bytes.sublist(sent, next),
        preferWriteWithoutResponse: false,
      );
      sent = next;
    }
  }

  Future<void> _validate() async {
    await transport.writeControlPoint([kDfuOpValidate]);
  }

  Future<void> _activateAndReset() async {
    try {
      // Bootloaders often disconnect immediately after receiving activate/reset.
      // Use write-without-response and treat expected disconnect timing as success.
      await transport.writeControlPoint([
        kDfuOpActivateAndReset,
      ], withoutResponse: true);
    } catch (e) {
      if (_isExpectedRebootDisconnect(e)) {
        return;
      }
      rethrow;
    }
  }

  bool _isExpectedRebootDisconnect(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('disconnect') ||
        message.contains('not connected') ||
        message.contains('gatt') ||
        message.contains('cancelled') ||
        message.contains('canceled');
  }

  Future<void> _awaitResponse(int requestedOp) async {
    final responseTimeout = _responseTimeoutForOp(requestedOp);
    final response = await transport.controlPointNotifications
        .firstWhere(
          (value) =>
              value.length >= 3 &&
              value[0] == kDfuResponseOpCode &&
              value[1] == requestedOp,
        )
        .timeout(
          responseTimeout,
          onTimeout: () {
            throw TimeoutException('dfu_response_timeout_op_$requestedOp');
          },
        );

    if (response[2] != kDfuStatusSuccess) {
      throw StateError('dfu_error_status_${response[2]}_op_$requestedOp');
    }
  }

  Future<void> _awaitResponseAfter(
    int requestedOp,
    Future<void> Function() action,
  ) async {
    final responseFuture = _awaitResponse(requestedOp);
    try {
      await action();
    } catch (error) {
      // Prevent unhandled timeout from the armed response waiter if action fails.
      unawaited(responseFuture.catchError((_) {}));
      rethrow;
    }
    await responseFuture;
  }

  Duration _responseTimeoutForOp(int opCode) {
    if (opCode == kDfuOpReceiveFirmware) {
      // Some devices take a long time to finalize flash writes before acking op_3.
      return timeout * 12;
    }
    if (opCode == kDfuOpValidate) {
      // Flash writes and image validation can take longer than control ops.
      return timeout * 12;
    }
    return timeout;
  }

  bool _isResponseTimeoutForOp(TimeoutException error, int opCode) {
    final marker = 'dfu_response_timeout_op_$opCode';
    final message = error.message;
    return message == marker || error.toString().contains(marker);
  }

  Future<int> _awaitPacketReceipt() async {
    final response = await transport.controlPointNotifications
        .firstWhere(
          (value) => value.isNotEmpty && value[0] == kDfuPacketReceiptNotif,
        )
        .timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('dfu_prn_timeout');
          },
        );

    if (response.length < 5) {
      throw StateError('dfu_prn_malformed');
    }

    final data = ByteData.sublistView(
      Uint8List.fromList(response.sublist(1, 5)),
    );
    return data.getUint32(0, Endian.little);
  }
}
