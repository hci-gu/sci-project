import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';

class JournalState extends StateNotifier<DateTime> {
  JournalState() : super(DateTime.now());

  Future createJournalEntry(
      JournalType type, Map<String, dynamic> values) async {
    Map<String, dynamic> info = {};

    String comment = values['comment'] as String;
    DateTime time = values['time'] as DateTime;

    switch (type) {
      case JournalType.pain:
        BodyPart bodyPart = BodyPart(
            values['bodyPartType'] as BodyPartType, values['side'] as Side?);
        info = {
          'painLevel': values['painLevel'] as int,
          'bodyPart': bodyPart.toString(),
        };
        break;
      case JournalType.pressureRelease:
        List<PressureReleaseExercise> exercises =
            values['exercises'] as List<PressureReleaseExercise>;
        info = {
          'exercises': exercises.map((e) => e.name.toString()).toList(),
        };
        break;
      case JournalType.pressureUlcer:
        PressureUlcerLocation location =
            values['location'] as PressureUlcerLocation;
        PressureUlcerType pressureUlcerType =
            values['pressureUlcerType'] as PressureUlcerType;
        info = {
          'pressureUlcerType': pressureUlcerType.name,
          'location': location.name,
        };
        break;
      case JournalType.bladderEmptying:
        UrineType type = values['urineType'] as UrineType;
        info = {
          'urineType': type.name,
          'smell': values['smell'] as bool,
        };
        break;
      case JournalType.urinaryTractInfection:
        UTIType type = values['utiType'] as UTIType;
        info = {
          'utiType': type.name,
        };
        break;
      case JournalType.exercise:
        Activity activity = values['activity'] as Activity;
        int minutes = values['minutes'] as int;
        info = {
          'activity': activity.name,
          'minutes': minutes,
        };
        break;
      default:
    }

    await Api().createJournalEntry({
      't': time.toIso8601String(),
      'type': type.name,
      'comment': comment,
      'info': info,
    });
    state = DateTime.now();
  }

  Future updateJournalEntry(
      JournalEntry entry, Map<String, dynamic> values) async {
    await Api().updateJournalEntry(
      entry.fromFormUpdate(values),
    );
    state = DateTime.now();
  }

  Future deleteJournalEntry(int id) async {
    await Api().deleteJournalEntry(id);
    state = DateTime.now();
  }
}

final updateJournalProvider =
    StateNotifierProvider<JournalState, DateTime>((ref) => JournalState());
