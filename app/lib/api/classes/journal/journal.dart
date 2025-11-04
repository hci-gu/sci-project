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

enum SelfAssessedPhysicalActivityTrainingDuration {
  none,
  lessThan30Minutes,
  minutes30To60,
  minutes60To90,
  minutes90To120,
  moreThan120Minutes,
}

SelfAssessedPhysicalActivityTrainingDuration
    selfAssessedPhysicalActivityTrainingDurationFromString(String value) {
  switch (value) {
    case 'none':
      return SelfAssessedPhysicalActivityTrainingDuration.none;
    case 'minutes1To30':
    case 'lessThan30Minutes':
      return SelfAssessedPhysicalActivityTrainingDuration.lessThan30Minutes;
    case 'minutes30To60':
      return SelfAssessedPhysicalActivityTrainingDuration.minutes30To60;
    case 'minutes60To90':
      return SelfAssessedPhysicalActivityTrainingDuration.minutes60To90;
    case 'minutes90To120':
    case 'hours1To3':
      return SelfAssessedPhysicalActivityTrainingDuration.minutes90To120;
    case 'moreThan120Minutes':
    case 'hours3To5':
    case 'hours5To7':
    case 'hours7To10':
    case 'hours10To15':
    case 'hours15To20':
    case 'moreThan20':
      return SelfAssessedPhysicalActivityTrainingDuration.moreThan120Minutes;
    default:
      return SelfAssessedPhysicalActivityTrainingDuration.none;
  }
}

extension SelfAssessedPhysicalActivityTrainingDurationExtension
    on SelfAssessedPhysicalActivityTrainingDuration {
  String displayString(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SelfAssessedPhysicalActivityTrainingDuration.none:
        return l10n.selfAssessedPhysicalActivityTrainingDurationNone;
      case SelfAssessedPhysicalActivityTrainingDuration.lessThan30Minutes:
        return l10n
            .selfAssessedPhysicalActivityTrainingDurationLessThan30Minutes;
      case SelfAssessedPhysicalActivityTrainingDuration.minutes30To60:
        return l10n.selfAssessedPhysicalActivityTrainingDuration30To60Minutes;
      case SelfAssessedPhysicalActivityTrainingDuration.minutes60To90:
        return l10n.selfAssessedPhysicalActivityTrainingDuration60To90Minutes;
      case SelfAssessedPhysicalActivityTrainingDuration.minutes90To120:
        return l10n.selfAssessedPhysicalActivityTrainingDuration90To120Minutes;
      case SelfAssessedPhysicalActivityTrainingDuration.moreThan120Minutes:
        return l10n
            .selfAssessedPhysicalActivityTrainingDurationMoreThan120Minutes;
    }
  }
}

enum SelfAssessedPhysicalActivityEverydayDuration {
  none,
  lessThan30Minutes,
  minutes30To60,
  minutes60To90,
  minutes90To150,
  minutes150To300,
  moreThan300Minutes,
}

SelfAssessedPhysicalActivityEverydayDuration
    selfAssessedPhysicalActivityEverydayDurationFromString(String value) {
  switch (value) {
    case 'none':
      return SelfAssessedPhysicalActivityEverydayDuration.none;
    case 'minutes1To30':
    case 'lessThan30Minutes':
      return SelfAssessedPhysicalActivityEverydayDuration.lessThan30Minutes;
    case 'minutes30To60':
      return SelfAssessedPhysicalActivityEverydayDuration.minutes30To60;
    case 'minutes60To90':
      return SelfAssessedPhysicalActivityEverydayDuration.minutes60To90;
    case 'minutes90To150':
    case 'hours1To3':
      return SelfAssessedPhysicalActivityEverydayDuration.minutes90To150;
    case 'minutes150To300':
    case 'hours3To5':
      return SelfAssessedPhysicalActivityEverydayDuration.minutes150To300;
    case 'moreThan300Minutes':
    case 'hours5To7':
    case 'hours7To10':
    case 'hours10To15':
    case 'hours15To20':
    case 'moreThan20':
      return SelfAssessedPhysicalActivityEverydayDuration.moreThan300Minutes;
    default:
      return SelfAssessedPhysicalActivityEverydayDuration.none;
  }
}

extension SelfAssessedPhysicalActivityEverydayDurationExtension
    on SelfAssessedPhysicalActivityEverydayDuration {
  String displayString(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SelfAssessedPhysicalActivityEverydayDuration.none:
        return l10n.selfAssessedPhysicalActivityEverydayDurationNone;
      case SelfAssessedPhysicalActivityEverydayDuration.lessThan30Minutes:
        return l10n
            .selfAssessedPhysicalActivityEverydayDurationLessThan30Minutes;
      case SelfAssessedPhysicalActivityEverydayDuration.minutes30To60:
        return l10n.selfAssessedPhysicalActivityEverydayDuration30To60Minutes;
      case SelfAssessedPhysicalActivityEverydayDuration.minutes60To90:
        return l10n.selfAssessedPhysicalActivityEverydayDuration60To90Minutes;
      case SelfAssessedPhysicalActivityEverydayDuration.minutes90To150:
        return l10n.selfAssessedPhysicalActivityEverydayDuration90To150Minutes;
      case SelfAssessedPhysicalActivityEverydayDuration.minutes150To300:
        return l10n.selfAssessedPhysicalActivityEverydayDuration150To300Minutes;
      case SelfAssessedPhysicalActivityEverydayDuration.moreThan300Minutes:
        return l10n
            .selfAssessedPhysicalActivityEverydayDurationMoreThan300Minutes;
    }
  }
}

enum SelfAssessedSedentaryDuration {
  almostAllDay,
  hours13To15,
  hours10To12,
  hours7To9,
  hours4To6,
  hours1To3,
  never,
}

SelfAssessedSedentaryDuration selfAssessedSedentaryDurationFromString(
    String value) {
  switch (value) {
    case 'almostAllDay':
    case 'hours15To17':
    case 'moreThan17':
      return SelfAssessedSedentaryDuration.almostAllDay;
    case 'hours13To15':
      return SelfAssessedSedentaryDuration.hours13To15;
    case 'hours11To13':
    case 'hours9To11':
    case 'hours10To12':
      return SelfAssessedSedentaryDuration.hours10To12;
    case 'hours7To9':
      return SelfAssessedSedentaryDuration.hours7To9;
    case 'hours5To7':
    case 'hours4To6':
      return SelfAssessedSedentaryDuration.hours4To6;
    case 'hours3To5':
    case 'hours1To3':
      return SelfAssessedSedentaryDuration.hours1To3;
    case 'lessThanOneHour':
      return SelfAssessedSedentaryDuration.hours1To3;
    case 'never':
      return SelfAssessedSedentaryDuration.never;
    default:
      return SelfAssessedSedentaryDuration.hours1To3;
  }
}

extension SelfAssessedSedentaryDurationExtension
    on SelfAssessedSedentaryDuration {
  String displayString(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SelfAssessedSedentaryDuration.almostAllDay:
        return l10n.selfAssessedSedentaryDurationAlmostAllDay;
      case SelfAssessedSedentaryDuration.hours13To15:
        return l10n.selfAssessedSedentaryDuration13To15Hours;
      case SelfAssessedSedentaryDuration.hours10To12:
        return l10n.selfAssessedSedentaryDuration10To12Hours;
      case SelfAssessedSedentaryDuration.hours7To9:
        return l10n.selfAssessedSedentaryDuration7To9Hours;
      case SelfAssessedSedentaryDuration.hours4To6:
        return l10n.selfAssessedSedentaryDuration4To6Hours;
      case SelfAssessedSedentaryDuration.hours1To3:
        return l10n.selfAssessedSedentaryDuration1To3Hours;
      case SelfAssessedSedentaryDuration.never:
        return l10n.selfAssessedSedentaryDurationNever;
    }
  }
}

class SelfAssessedPhysicalActivityEntry extends JournalEntry {
  final SelfAssessedPhysicalActivityTrainingDuration trainingDuration;
  final SelfAssessedPhysicalActivityEverydayDuration everydayActivityDuration;
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
      trainingDuration:
          selfAssessedPhysicalActivityTrainingDurationFromString(
        info['trainingDuration'] ?? 'none',
      ),
      everydayActivityDuration:
          selfAssessedPhysicalActivityEverydayDurationFromString(
        info['everydayActivityDuration'] ?? 'none',
      ),
      sedentaryDuration: selfAssessedSedentaryDurationFromString(
        info['sedentaryDuration'] ?? 'hours1To3',
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
      trainingDuration: values['trainingDuration']
          as SelfAssessedPhysicalActivityTrainingDuration,
      everydayActivityDuration: values['everydayActivityDuration']
          as SelfAssessedPhysicalActivityEverydayDuration,
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
