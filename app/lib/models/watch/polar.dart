import 'package:collection/collection.dart';
import 'package:polar/polar.dart';

class PolarState {
  final bool isRecording;
  final List<PolarOfflineRecordingEntry> recordings;

  PolarState({required this.isRecording, required this.recordings});
}

class PolarService {
  static PolarService? _instance;
  final polar = Polar();
  bool connected = false;

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

  Future start({bool requestPermissions = true}) async {
    // polar.batteryLevel.listen((e) => print('Battery: ${e.level}'));
    // polar.deviceConnecting.listen((_) => print('Device connecting'));
    polar.deviceConnected.listen((_) {
      connected = true;
    });
    polar.deviceDisconnected.listen((_) {
      connected = false;
    });

    await polar.connectToDevice(
      identifier,
      requestPermissions: requestPermissions,
    );

    // await startRecording(PolarDataType.acc);
    // await startRecording(PolarDataType.hr);
    return connected;
  }

  Future<PolarState> getState() async {
    List<PolarOfflineRecordingEntry> entries = await listRecordings();
    List<PolarDataType> currentRecordings = await polar
        .getOfflineRecordingStatus(identifier);

    bool isRecording = currentRecordings.isNotEmpty;

    return PolarState(isRecording: isRecording, recordings: entries);
  }

  Future<List<PolarOfflineRecordingEntry>> listRecordings() async {
    List<PolarOfflineRecordingEntry> entries = await polar
        .listOfflineRecordings(identifier);

    return entries;
  }

  Future<void> startRecording(PolarDataType type) async {
    List<PolarDataType> currentRecordings = await polar
        .getOfflineRecordingStatus(identifier);
    if (!currentRecordings.contains(type)) {
      if (type == PolarDataType.acc) {
        Map<PolarSettingType, int> settings = {
          PolarSettingType.sampleRate: 52,
          PolarSettingType.resolution: 16,
          PolarSettingType.range: 8,
          PolarSettingType.channels: 3,
        };
        await polar.startOfflineRecording(
          identifier,
          type,
          settings: PolarSensorSetting(settings),
        );
      } else if (type == PolarDataType.hr) {
        Map<PolarSettingType, int> settings = {};
        await polar.startOfflineRecording(
          identifier,
          type,
          settings: PolarSensorSetting(settings),
        );
      } else {
        throw ArgumentError('Unsupported data type: $type');
      }
    }
  }

  Future<void> stopRecording(PolarDataType type) async {
    List<PolarDataType> currentRecordings = await polar
        .getOfflineRecordingStatus(identifier);

    if (currentRecordings.contains(type)) {
      await polar.stopOfflineRecording(identifier, type);
    }
  }

  Future<void> deleteAllRecordings() async {
    print("Deleting all recordings for $identifier");
    List<PolarOfflineRecordingEntry> entries = await listRecordings();
    for (var entry in entries) {
      await polar.removeOfflineRecord(identifier, entry);
    }
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

    HrOfflineRecording? hrRecording = await polar.getOfflineHrRecord(
      identifier,
      hrEntry,
    );
    AccOfflineRecording? accRecording = await polar.getOfflineAccRecord(
      identifier,
      accEntry,
    );

    return (accRecording, hrRecording);
  }

  Future stop() async {
    await polar.disconnectFromDevice(identifier);
  }
}
