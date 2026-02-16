import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:scimovement/models/watch/dfu/dfu_constants.dart';

class DfuTransport {
  final BluetoothDevice device;
  BluetoothCharacteristic? _controlPoint;
  BluetoothCharacteristic? _packet;

  DfuTransport(this.device);

  BluetoothCharacteristic get controlPoint {
    final c = _controlPoint;
    if (c == null) {
      throw StateError('dfu_control_point_missing');
    }
    return c;
  }

  BluetoothCharacteristic get packet {
    final c = _packet;
    if (c == null) {
      throw StateError('dfu_packet_missing');
    }
    return c;
  }

  Future<void> initialize() async {
    final services = await device.discoverServices();
    for (final service in services) {
      if (service.uuid == kDfuServiceUuid) {
        for (final c in service.characteristics) {
          if (c.uuid == kDfuControlPointUuid) {
            _controlPoint = c;
          } else if (c.uuid == kDfuPacketUuid) {
            _packet = c;
          }
        }
      }
    }

    if (_controlPoint == null || _packet == null) {
      throw StateError('dfu_characteristics_not_found');
    }

    await _controlPoint!.setNotifyValue(true);
  }

  Stream<List<int>> get controlPointNotifications =>
      controlPoint.onValueReceived;

  Future<void> writeControlPoint(
    List<int> data, {
    bool withoutResponse = false,
  }) async {
    final c = controlPoint;
    final supportsWrite = c.properties.write;
    final supportsWriteNoResp = c.properties.writeWithoutResponse;

    if (withoutResponse && supportsWriteNoResp) {
      await c.write(data, withoutResponse: true);
      return;
    }
    if (!withoutResponse && supportsWrite) {
      await c.write(data, withoutResponse: false);
      return;
    }
    if (supportsWrite) {
      await c.write(data, withoutResponse: false);
      return;
    }
    if (supportsWriteNoResp) {
      await c.write(data, withoutResponse: true);
      return;
    }

    throw StateError('dfu_control_point_write_not_supported');
  }

  Future<void> writePacket(List<int> data) async {
    final c = packet;
    final supportsWriteNoResp = c.properties.writeWithoutResponse;
    final supportsWrite = c.properties.write;

    if (supportsWriteNoResp) {
      await c.write(data, withoutResponse: true);
      return;
    }
    if (supportsWrite) {
      await c.write(data, withoutResponse: false);
      return;
    }

    throw StateError('dfu_packet_write_not_supported');
  }

  Future<void> requestMtu(int mtu) async {
    try {
      await device.requestMtu(mtu);
    } catch (_) {
      // MTU negotiation is optional and may not be supported.
    }
  }
}
