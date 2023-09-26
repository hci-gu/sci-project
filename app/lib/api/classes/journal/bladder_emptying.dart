import 'package:flutter/material.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum UrineType { normal, cloudy, bloody }

extension UrineTypeExtensions on UrineType {
  String displayString(BuildContext context) {
    switch (this) {
      case UrineType.normal:
        return AppLocalizations.of(context)!.urineTypeNormal;
      case UrineType.cloudy:
        return AppLocalizations.of(context)!.urineTypeCloudy;
      case UrineType.bloody:
        return AppLocalizations.of(context)!.urineTypeBlood;
    }
  }
}

UrineType urineTypeFromString(String type) {
  switch (type) {
    case 'normal':
      return UrineType.normal;
    case 'cloudy':
      return UrineType.cloudy;
    case 'bloody':
      return UrineType.bloody;
    default:
      return UrineType.normal;
  }
}

class BladderEmptyingEntry extends JournalEntry {
  final UrineType urineType;
  final bool smell;

  BladderEmptyingEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.urineType,
    required this.smell,
  });

  factory BladderEmptyingEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    return BladderEmptyingEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      urineType: urineTypeFromString(info['urineType']),
      smell: info['smell'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'urineType': urineType.toString(),
        'smell': smell,
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return BladderEmptyingEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      urineType: values['urineType'] as UrineType,
      smell: values['smell'] as bool,
    );
  }

  @override
  String title(BuildContext context) {
    return AppLocalizations.of(context)!.bladderEmptying;
  }

  @override
  String shortcutTitle(BuildContext context) {
    return title(context);
  }
}
