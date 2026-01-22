import 'package:flutter_blue_plus/flutter_blue_plus.dart';

final Guid kDfuServiceUuid = Guid('00001530-1212-efde-1523-785feabcd123');
final Guid kDfuControlPointUuid =
    Guid('00001531-1212-efde-1523-785feabcd123');
final Guid kDfuPacketUuid = Guid('00001532-1212-efde-1523-785feabcd123');

const int kDfuOpStartDfu = 0x01;
const int kDfuOpInitPacket = 0x02;
const int kDfuOpReceiveFirmware = 0x03;
const int kDfuOpValidate = 0x04;
const int kDfuOpActivateAndReset = 0x05;
const int kDfuOpPacketReceiptNotifReq = 0x08;

const int kDfuResponseOpCode = 0x10;
const int kDfuPacketReceiptNotif = 0x11;

const int kDfuImageTypeApplication = 0x04;

const int kDfuStatusSuccess = 0x01;

const int kDfuDefaultPrn = 10;
const int kDfuDefaultChunkSize = 20;
