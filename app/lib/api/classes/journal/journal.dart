import 'package:flutter/material.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

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
  bowelEmptying,
  leakage,
  exercise,
  selfAssessedPhysicalActivity,
  spasticity,
}

enum TimelineType {
  pain,
  pressureRelease,
  pressureUlcer,
  urinaryTractInfection,
  bladderEmptying,
  bowelEmptying,
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
      case JournalType.bowelEmptying:
        return AppLocalizations.of(context)!.bowelEmptying;
      case JournalType.urinaryTractInfection:
        return AppLocalizations.of(context)!.urinaryTractInfection;
      case JournalType.leakage:
        return AppLocalizations.of(context)!.leakage;
      case JournalType.exercise:
        return AppLocalizations.of(context)!.exercise;
      case JournalType.selfAssessedPhysicalActivity:
        return AppLocalizations.of(context)!.selfAssessedPhysicalActivity;
      case JournalType.spasticity:
        return AppLocalizations.of(context)!.spasticity;
      default:
        return toString();
    }
  }

  bool get hasGoal {
    switch (this) {
      case JournalType.bladderEmptying:
      case JournalType.pressureRelease:
        return true;
      default:
        return false;
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
    case 'bowelEmptying':
      return JournalType.bowelEmptying;
    case 'urinaryTractInfection':
      return JournalType.urinaryTractInfection;
    case 'leakage':
      return JournalType.leakage;
    case 'exercise':
      return JournalType.exercise;
    case 'selfAssessedPhysicalActivity':
      return JournalType.selfAssessedPhysicalActivity;
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
        return AppLocalizations.of(context)!.painAndDiscomfort;
      case TimelineType.pressureRelease:
        return AppLocalizations.of(context)!.pressureRelease;
      case TimelineType.pressureUlcer:
        return AppLocalizations.of(context)!.pressureUlcer;
      case TimelineType.bladderEmptying:
        return AppLocalizations.of(context)!.bladderEmptying;
      case TimelineType.bowelEmptying:
        return AppLocalizations.of(context)!.bowelEmptying;
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

enum SelfAssessedPhysicalActivityDuration {
  none,
  minutes1To30,
  minutes30To60,
  hours1To3,
  hours3To5,
  hours5To7,
  hours7To10,
  hours10To15,
  hours15To20,
  moreThan20,
}

SelfAssessedPhysicalActivityDuration
    selfAssessedPhysicalActivityDurationFromString(String value) {
  switch (value) {
    case 'minutes1To30':
      return SelfAssessedPhysicalActivityDuration.minutes1To30;
    case 'minutes30To60':
      return SelfAssessedPhysicalActivityDuration.minutes30To60;
    case 'hours1To3':
      return SelfAssessedPhysicalActivityDuration.hours1To3;
    case 'hours3To5':
      return SelfAssessedPhysicalActivityDuration.hours3To5;
    case 'hours5To7':
      return SelfAssessedPhysicalActivityDuration.hours5To7;
    case 'hours7To10':
      return SelfAssessedPhysicalActivityDuration.hours7To10;
    case 'hours10To15':
      return SelfAssessedPhysicalActivityDuration.hours10To15;
    case 'hours15To20':
      return SelfAssessedPhysicalActivityDuration.hours15To20;
    case 'moreThan20':
      return SelfAssessedPhysicalActivityDuration.moreThan20;
    default:
      return SelfAssessedPhysicalActivityDuration.none;
  }
}

extension SelfAssessedPhysicalActivityDurationExtension
    on SelfAssessedPhysicalActivityDuration {
  String displayString(BuildContext context) {
    switch (this) {
      case SelfAssessedPhysicalActivityDuration.none:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDurationNone;
      case SelfAssessedPhysicalActivityDuration.minutes1To30:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration1To30Minutes;
      case SelfAssessedPhysicalActivityDuration.minutes30To60:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration30To60Minutes;
      case SelfAssessedPhysicalActivityDuration.hours1To3:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration1To3Hours;
      case SelfAssessedPhysicalActivityDuration.hours3To5:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration3To5Hours;
      case SelfAssessedPhysicalActivityDuration.hours5To7:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration5To7Hours;
      case SelfAssessedPhysicalActivityDuration.hours7To10:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration7To10Hours;
      case SelfAssessedPhysicalActivityDuration.hours10To15:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration10To15Hours;
      case SelfAssessedPhysicalActivityDuration.hours15To20:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDuration15To20Hours;
      case SelfAssessedPhysicalActivityDuration.moreThan20:
        return AppLocalizations.of(context)!
            .selfAssessedPhysicalActivityDurationMoreThan20Hours;
    }
  }
}

enum SelfAssessedSedentaryDuration {
  lessThanOneHour,
  hours1To3,
  hours3To5,
  hours5To7,
  hours7To9,
  hours9To11,
  hours11To13,
  hours13To15,
  hours15To17,
  moreThan17,
}

SelfAssessedSedentaryDuration selfAssessedSedentaryDurationFromString(
    String value) {
  switch (value) {
    case 'hours1To3':
      return SelfAssessedSedentaryDuration.hours1To3;
    case 'hours3To5':
      return SelfAssessedSedentaryDuration.hours3To5;
    case 'hours5To7':
      return SelfAssessedSedentaryDuration.hours5To7;
    case 'hours7To9':
      return SelfAssessedSedentaryDuration.hours7To9;
    case 'hours9To11':
      return SelfAssessedSedentaryDuration.hours9To11;
    case 'hours11To13':
      return SelfAssessedSedentaryDuration.hours11To13;
    case 'hours13To15':
      return SelfAssessedSedentaryDuration.hours13To15;
    case 'hours15To17':
      return SelfAssessedSedentaryDuration.hours15To17;
    case 'moreThan17':
      return SelfAssessedSedentaryDuration.moreThan17;
    default:
      return SelfAssessedSedentaryDuration.lessThanOneHour;
  }
}

extension SelfAssessedSedentaryDurationExtension
    on SelfAssessedSedentaryDuration {
  String displayString(BuildContext context) {
    switch (this) {
      case SelfAssessedSedentaryDuration.lessThanOneHour:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDurationLessThanOneHour;
      case SelfAssessedSedentaryDuration.hours1To3:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration1To3Hours;
      case SelfAssessedSedentaryDuration.hours3To5:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration3To5Hours;
      case SelfAssessedSedentaryDuration.hours5To7:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration5To7Hours;
      case SelfAssessedSedentaryDuration.hours7To9:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration7To9Hours;
      case SelfAssessedSedentaryDuration.hours9To11:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration9To11Hours;
      case SelfAssessedSedentaryDuration.hours11To13:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration11To13Hours;
      case SelfAssessedSedentaryDuration.hours13To15:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration13To15Hours;
      case SelfAssessedSedentaryDuration.hours15To17:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDuration15To17Hours;
      case SelfAssessedSedentaryDuration.moreThan17:
        return AppLocalizations.of(context)!
            .selfAssessedSedentaryDurationMoreThan17Hours;
    }
  }
}

class SelfAssessedPhysicalActivityEntry extends JournalEntry {
  final SelfAssessedPhysicalActivityDuration trainingDuration;
  final SelfAssessedPhysicalActivityDuration everydayActivityDuration;
  final SelfAssessedSedentaryDuration sedentaryDuration;

  SelfAssessedPhysicalActivityEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.trainingDuration,
    required this.everydayActivityDuration,
    required this.sedentaryDuration,
  });

  factory SelfAssessedPhysicalActivityEntry.fromJson(
      Map<String, dynamic> json) {
    final Map<String, dynamic> info = json['info'] ?? {};
    return SelfAssessedPhysicalActivityEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'] ?? '',
      trainingDuration: selfAssessedPhysicalActivityDurationFromString(
        info['trainingDuration'] ?? 'none',
      ),
      everydayActivityDuration: selfAssessedPhysicalActivityDurationFromString(
        info['everydayActivityDuration'] ?? 'none',
      ),
      sedentaryDuration: selfAssessedSedentaryDurationFromString(
        info['sedentaryDuration'] ?? 'lessThanOneHour',
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'trainingDuration': trainingDuration.name,
        'everydayActivityDuration': everydayActivityDuration.name,
        'sedentaryDuration': sedentaryDuration.name,
      },
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return SelfAssessedPhysicalActivityEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      trainingDuration:
          values['trainingDuration'] as SelfAssessedPhysicalActivityDuration,
      everydayActivityDuration: values['everydayActivityDuration']
          as SelfAssessedPhysicalActivityDuration,
      sedentaryDuration:
          values['sedentaryDuration'] as SelfAssessedSedentaryDuration,
    );
  }

  @override
  String title(BuildContext context) {
    return AppLocalizations.of(context)!.selfAssessedPhysicalActivity;
  }

  @override
  String shortcutTitle(BuildContext context) {
    return title(context);
  }

  String summary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return '${l10n.selfAssessedPhysicalActivityTrainingLabel}: '
        '${trainingDuration.displayString(context)} · '
        '${l10n.selfAssessedPhysicalActivityEverydayLabel}: '
        '${everydayActivityDuration.displayString(context)} · '
        '${l10n.selfAssessedPhysicalActivitySedentaryLabel}: '
        '${sedentaryDuration.displayString(context)}';
  }

  @override
  String get identifier => 'selfAssessedPhysicalActivity';

  @override
  TimelineType get timelineType => TimelineType.exercise;
}
