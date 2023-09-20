import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:scimovement/api/classes/journal/journal.dart';

enum PressureReleaseExercise {
  forwards,
  rightSide,
  leftSide,
  lying,
}

PressureReleaseExercise prExerciseFromString(String string) {
  switch (string) {
    case 'forwards':
      return PressureReleaseExercise.forwards;
    case 'rightSide':
      return PressureReleaseExercise.rightSide;
    case 'leftSide':
      return PressureReleaseExercise.leftSide;
    case 'lying':
      return PressureReleaseExercise.lying;
    default:
      return PressureReleaseExercise.forwards;
  }
}

extension PressureReleaseExerciseExtension on PressureReleaseExercise {
  String get asset {
    switch (this) {
      case PressureReleaseExercise.forwards:
        return 'assets/images/pressure_release_forward.jpeg';
      case PressureReleaseExercise.rightSide:
        return 'assets/images/pressure_release_right.jpeg';
      case PressureReleaseExercise.leftSide:
        return 'assets/images/pressure_release_left.jpeg';
      case PressureReleaseExercise.lying:
        return 'assets/images/pressure_release_lying.jpeg';
    }
  }

  String displayString(BuildContext context) {
    switch (this) {
      case PressureReleaseExercise.forwards:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLeanForward;
      case PressureReleaseExercise.rightSide:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLeanRight;
      case PressureReleaseExercise.leftSide:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLeanLeft;
      case PressureReleaseExercise.lying:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLying;
    }
  }

  String description(BuildContext context) {
    switch (this) {
      case PressureReleaseExercise.forwards:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLeanForwardDescription;
      case PressureReleaseExercise.rightSide:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLeanRightDescription;
      case PressureReleaseExercise.leftSide:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLeanLeftDescription;
      case PressureReleaseExercise.lying:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLyingDescription;
    }
  }
}

class PressureReleaseEntry extends JournalEntry {
  final List<PressureReleaseExercise> exercises;

  PressureReleaseEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.exercises,
  });

  factory PressureReleaseEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    List<dynamic> exercises = info['exercises'];

    return PressureReleaseEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'] ?? '',
      exercises: exercises.map((e) => prExerciseFromString(e)).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'exercises': exercises
            .map(
              (e) => e.name.toString(),
            )
            .toList(),
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return PressureReleaseEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      exercises: values['exercises'] as List<PressureReleaseExercise>,
    );
  }

  @override
  String title(BuildContext context) {
    return AppLocalizations.of(context)!.pressureRelease;
  }

  @override
  String shortcutTitle(BuildContext context) {
    return title(context);
  }

  @override
  String get identifier {
    return 'pressureRelease';
  }
}
