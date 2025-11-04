import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/bowel_emptying.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/api/classes/journal/spasticity.dart';

class JournalState extends StateNotifier<DateTime> {
  JournalState() : super(DateTime.now());

  Future createJournalEntry(
      JournalType type, Map<String, dynamic> values) async {
    Map<String, dynamic> info = {};

    String comment = values['comment'] as String;
    DateTime time = values['time'] as DateTime;

    switch (type) {
      case JournalType.musclePain:
      case JournalType.neuropathicPain:
        BodyPart bodyPart = BodyPart(
          values['bodyPartType'] as BodyPartType,
          values['side'] as Side?,
        );
        info = {
          'painLevel': values['painLevel'] as int,
          'bodyPart': bodyPart.toString(),
        };
        break;
      case JournalType.spasticity:
        info = {
          'level': values['level'] as int,
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
      case JournalType.bowelEmptying:
        StoolType type = values['stoolType'] as StoolType;
        info = {
          'stoolType': type.name,
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
      case JournalType.selfAssessedPhysicalActivity:
        SelfAssessedPhysicalActivityTrainingDuration training =
            values['trainingDuration']
                as SelfAssessedPhysicalActivityTrainingDuration;
        SelfAssessedPhysicalActivityEverydayDuration everyday =
            values['everydayActivityDuration']
                as SelfAssessedPhysicalActivityEverydayDuration;
        SelfAssessedSedentaryDuration sedentary =
            values['sedentaryDuration'] as SelfAssessedSedentaryDuration;
        info = {
          'trainingDuration': training.name,
          'everydayActivityDuration': everyday.name,
          'sedentaryDuration': sedentary.name,
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

  Future setJournalEntryValue(JournalEntry entry, int updatedValue) async {
    if (entry is PainLevelEntry) {
      await Api().createJournalEntry({
        't': DateTime.now().toIso8601String(),
        'type': entry.type.name,
        'comment': '',
        'info': {
          'bodyPart': entry.bodyPart.toString(),
          'painLevel': updatedValue,
        },
      });
    } else if (entry is SpasticityEntry) {
      await Api().createJournalEntry({
        't': DateTime.now().toIso8601String(),
        'type': entry.type.name,
        'comment': '',
        'info': {
          'level': updatedValue,
        },
      });
    }
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
