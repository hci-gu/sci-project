import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:scimovement/api/classes/journal/pain.dart';
export 'package:scimovement/api/classes/journal/uti.dart';
export 'package:scimovement/api/classes/journal/pressure_ulcer.dart';
export 'package:scimovement/api/classes/journal/pressure_release.dart';
export 'package:scimovement/api/classes/journal/bladder_emptying.dart';

enum JournalType {
  musclePain,
  neuropathicPain,
  pressureRelease,
  pressureUlcer,
  urinaryTractInfection,
  bladderEmptying,
  leakage,
  exercise,
  spasticity,
}

enum TimelineType {
  pain,
  pressureRelease,
  pressureUlcer,
  urinaryTractInfection,
  bladderEmptying,
  leakage,
  exercise,
  spasticity,
  movement,
}

extension JournalTypeDisplayAsString on JournalType {
  String displayString(BuildContext context) {
    switch (this) {
      case JournalType.musclePain:
        return AppLocalizations.of(context)!.musclePainTitle;
      case JournalType.neuropathicPain:
        return AppLocalizations.of(context)!.neuropathicPain;
      case JournalType.pressureRelease:
        return AppLocalizations.of(context)!.pressureRelease;
      case JournalType.pressureUlcer:
        return AppLocalizations.of(context)!.pressureUlcer;
      case JournalType.bladderEmptying:
        return AppLocalizations.of(context)!.bladderEmptying;
      case JournalType.urinaryTractInfection:
        return AppLocalizations.of(context)!.urinaryTractInfection;
      case JournalType.leakage:
        return AppLocalizations.of(context)!.leakage;
      case JournalType.exercise:
        return AppLocalizations.of(context)!.exercise;
      case JournalType.spasticity:
        return AppLocalizations.of(context)!.spasticity;
      default:
        return toString();
    }
  }
}

JournalType journalTypeFromString(String type) {
  switch (type) {
    case 'pressureUlcer':
      return JournalType.pressureUlcer;
    case 'pressureRelease':
      return JournalType.pressureRelease;
    case 'pain':
    case 'musclePain':
      return JournalType.musclePain;
    case 'neuropathicPain':
      return JournalType.neuropathicPain;
    case 'bladderEmptying':
      return JournalType.bladderEmptying;
    case 'urinaryTractInfection':
      return JournalType.urinaryTractInfection;
    case 'leakage':
      return JournalType.leakage;
    case 'exercise':
      return JournalType.exercise;
    case 'spasticity':
      return JournalType.spasticity;
    default:
      return JournalType.musclePain;
  }
}

extension TimelineTypeDisplayAsString on TimelineType {
  String displayString(BuildContext context) {
    switch (this) {
      case TimelineType.pain:
        return AppLocalizations.of(context)!.pain;
      case TimelineType.pressureRelease:
        return AppLocalizations.of(context)!.pressureRelease;
      case TimelineType.pressureUlcer:
        return AppLocalizations.of(context)!.pressureUlcer;
      case TimelineType.bladderEmptying:
        return AppLocalizations.of(context)!.bladderEmptying;
      case TimelineType.urinaryTractInfection:
        return AppLocalizations.of(context)!.urinaryTractInfection;
      case TimelineType.leakage:
        return AppLocalizations.of(context)!.leakage;
      case TimelineType.exercise:
        return AppLocalizations.of(context)!.exercise;
      case TimelineType.spasticity:
        return AppLocalizations.of(context)!.spasticity;
      case TimelineType.movement:
        return AppLocalizations.of(context)!.movement;
      default:
        return toString();
    }
  }
}

class JournalEntry {
  final int id;
  final DateTime time;
  final JournalType type;
  final String comment;

  JournalEntry({
    required this.id,
    required this.time,
    required this.type,
    required this.comment,
  });

  JournalEntry copyWith({
    DateTime? updateTime,
  }) {
    return JournalEntry(
      id: id,
      time: updateTime ?? time,
      type: type,
      comment: comment,
    );
  }

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'comment': comment,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
    );
  }

  String title(BuildContext context) {
    if (type == JournalType.leakage) {
      return AppLocalizations.of(context)!.leakage;
    }
    return '';
  }

  String shortcutTitle(BuildContext context) {
    if (type == JournalType.leakage) {
      return AppLocalizations.of(context)!.leakage;
    }
    return '';
  }

  JournalEntry fromFormUpdate(Map<String, dynamic> values) => this;

  String get identifier => type.name;

  TimelineType get timelineType => TimelineType.pain;
}
