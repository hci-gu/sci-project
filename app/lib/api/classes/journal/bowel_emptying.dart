import 'package:flutter/material.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

enum StoolType { type1, type2, type3, type4, type5, type6, type7 }

extension StoolTypeExtension on StoolType {
  String displayString(BuildContext context) {
    switch (this) {
      case StoolType.type1:
        return AppLocalizations.of(context)!.stoolType1;
      case StoolType.type2:
        return AppLocalizations.of(context)!.stoolType2;
      case StoolType.type3:
        return AppLocalizations.of(context)!.stoolType3;
      case StoolType.type4:
        return AppLocalizations.of(context)!.stoolType4;
      case StoolType.type5:
        return AppLocalizations.of(context)!.stoolType5;
      case StoolType.type6:
        return AppLocalizations.of(context)!.stoolType6;
      case StoolType.type7:
        return AppLocalizations.of(context)!.stoolType7;
    }
  }

  String description(BuildContext context) {
    switch (this) {
      case StoolType.type1:
        return AppLocalizations.of(context)!.stoolType1Description;
      case StoolType.type2:
        return AppLocalizations.of(context)!.stoolType2Description;
      case StoolType.type3:
        return AppLocalizations.of(context)!.stoolType3Description;
      case StoolType.type4:
        return AppLocalizations.of(context)!.stoolType4Description;
      case StoolType.type5:
        return AppLocalizations.of(context)!.stoolType5Description;
      case StoolType.type6:
        return AppLocalizations.of(context)!.stoolType6Description;
      case StoolType.type7:
        return AppLocalizations.of(context)!.stoolType7Description;
    }
  }
}

StoolType stoolTypeFromString(String type) {
  switch (type) {
    case 'type1':
      return StoolType.type1;
    case 'type2':
      return StoolType.type2;
    case 'type3':
      return StoolType.type3;
    case 'type4':
      return StoolType.type4;
    case 'type5':
      return StoolType.type5;
    case 'type6':
      return StoolType.type6;
    case 'type7':
      return StoolType.type7;
    default:
      return StoolType.type1;
  }
}

class BowelEmptyingEntry extends JournalEntry {
  final StoolType stoolType;

  BowelEmptyingEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.stoolType,
  });

  factory BowelEmptyingEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    return BowelEmptyingEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      stoolType: stoolTypeFromString(info['stoolType']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'stoolType': stoolType.toString(),
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return BowelEmptyingEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      stoolType: values['stoolType'] as StoolType,
    );
  }

  @override
  String title(BuildContext context) {
    return AppLocalizations.of(context)!.bowelEmptying;
  }

  @override
  String shortcutTitle(BuildContext context) {
    return title(context);
  }

  @override
  TimelineType get timelineType => TimelineType.bladderEmptying;
}
