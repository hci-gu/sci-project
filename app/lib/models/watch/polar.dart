import 'package:collection/collection.dart';
import 'package:polar/polar.dart';

class PolarService {
  static PolarService? _instance;
  final polar = Polar();

  final String identifier;

  PolarService._(this.identifier);

  static PolarService get instance {
    if (_instance == null) {
      throw StateError(
        'PolarService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  static void initialize(String identifier) {
    _instance = PolarService._(identifier);
  }

  static void dispose() {
    _instance = null;
  }

  Future start() async {
    // polar.batteryLevel.listen((e) => print('Battery: ${e.level}'));
    // polar.deviceConnecting.listen((_) => print('Device connecting'));
    // polar.deviceConnected.listen((_) => print('Device connected'));
    // polar.deviceDisconnected.listen((_) => print('Device disconnected'));

    await polar.connectToDevice(identifier);
    await Future.delayed(Duration(seconds: 5));

    List<PolarDataType> currentRecordings = await polar
        .getOfflineRecordingStatus(identifier);

    if (currentRecordings.isEmpty) {
      await polar.startOfflineRecording(identifier, PolarDataType.hr);
    }
  }

  Future<List<PolarOfflineRecordingEntry>> listRecordings() async {
    List<PolarOfflineRecordingEntry> entries = await polar
        .listOfflineRecordings(identifier);

    return entries;
  }

  Future<void> deleteRecording(PolarOfflineRecordingEntry entry) async {
    await polar.removeOfflineRecord(identifier, entry);
  }

  Future<(AccOfflineRecording?, HrOfflineRecording?)> getRecordings(
    List<PolarOfflineRecordingEntry> entries,
  ) async {
    PolarOfflineRecordingEntry? accEntry = entries.firstWhereOrNull(
      (e) => e.type == PolarDataType.acc,
    );
    PolarOfflineRecordingEntry? hrEntry = entries.firstWhereOrNull(
      (e) => e.type == PolarDataType.hr,
    );

    if (accEntry == null || hrEntry == null) {
      return (null, null);
    }

    AccOfflineRecording? accRecording = await polar.getOfflineAccRecord(
      identifier,
      accEntry,
    );
    HrOfflineRecording? hrRecording = await polar.getOfflineHrRecord(
      identifier,
      hrEntry,
    );

    return (accRecording, hrRecording);
  }

  Future stop() async {
    await polar.disconnectFromDevice(identifier);
  }
}
