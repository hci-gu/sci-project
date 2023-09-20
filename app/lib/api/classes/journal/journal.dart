import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:scimovement/api/classes/journal/pain.dart';
export 'package:scimovement/api/classes/journal/uti.dart';
export 'package:scimovement/api/classes/journal/pressure_ulcer.dart';
export 'package:scimovement/api/classes/journal/pressure_release.dart';
export 'package:scimovement/api/classes/journal/bladder_emptying.dart';

enum JournalType {
  pain,
  pressureRelease,
  pressureUlcer,
  urinaryTractInfection,
  bladderEmptying,
  leakage,
}

extension JournalTypeDisplayAsString on JournalType {
  String displayString(BuildContext context) {
    switch (this) {
      case JournalType.pain:
        return AppLocalizations.of(context)!.pain;
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
      return JournalType.pain;
    case 'bladderEmptying':
      return JournalType.bladderEmptying;
    case 'urinaryTractInfection':
      return JournalType.urinaryTractInfection;
    case 'leakage':
      return JournalType.leakage;
    default:
      return JournalType.pain;
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
}
