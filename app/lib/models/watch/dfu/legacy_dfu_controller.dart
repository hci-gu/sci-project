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

    await _startDfu();
    await _sendImageSize(package.imageSize);
    await _awaitResponse(kDfuOpStartDfu);

    cancelToken.throwIfCancelled();
    onProgress?.call(const DfuProgress(phase: 'init_packet'));

    await _sendInitPacket(package.datBytes);
    await _awaitResponse(kDfuOpInitPacket);

    cancelToken.throwIfCancelled();
    onProgress?.call(
      DfuProgress(
        phase: 'transfer',
        current: 0,
        total: package.binBytes.length,
      ),
    );

    await _setPrn(prn);
    await _sendFirmware(package.binBytes, onProgress: onProgress);

    await _awaitResponse(kDfuOpReceiveFirmware);

    cancelToken.throwIfCancelled();
    onProgress?.call(const DfuProgress(phase: 'validate'));

    await _validate();
    await _awaitResponse(kDfuOpValidate);

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
    await transport.writePacket(bytes.buffer.asUint8List());
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
      await transport.writePacket(bytes.sublist(sent, next));
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
    final response = await transport.controlPointNotifications
        .firstWhere(
          (value) =>
              value.length >= 3 &&
              value[0] == kDfuResponseOpCode &&
              value[1] == requestedOp,
        )
        .timeout(
          timeout,
          onTimeout: () {
            throw TimeoutException('dfu_response_timeout');
          },
        );

    if (response[2] != kDfuStatusSuccess) {
      throw StateError('dfu_error_status_${response[2]}');
    }
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
