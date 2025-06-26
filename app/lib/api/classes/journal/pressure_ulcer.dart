import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:flutter/material.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

enum PressureUlcerType {
  none,
  category1,
  category2,
  category3,
  category4,
}

PressureUlcerType pressureUlcerTypefromString(String type) {
  switch (type) {
    case 'none':
      return PressureUlcerType.none;
    case 'category1':
      return PressureUlcerType.category1;
    case 'category2':
      return PressureUlcerType.category2;
    case 'category3':
      return PressureUlcerType.category3;
    case 'category4':
      return PressureUlcerType.category4;
    default:
      return PressureUlcerType.none;
  }
}

extension PressureUlcerTypeExtension on PressureUlcerType {
  String displayString(BuildContext context) {
    switch (this) {
      case PressureUlcerType.none:
        return AppLocalizations.of(context)!.noPressureUlcer;
      case PressureUlcerType.category1:
        return AppLocalizations.of(context)!.pressureUlcerCategory1;
      case PressureUlcerType.category2:
        return AppLocalizations.of(context)!.pressureUlcerCategory2;
      case PressureUlcerType.category3:
        return AppLocalizations.of(context)!.pressureUlcerCategory3;
      case PressureUlcerType.category4:
        return AppLocalizations.of(context)!.pressureUlcerCategory4;
    }
  }

  String description(BuildContext context) {
    switch (this) {
      case PressureUlcerType.none:
        return AppLocalizations.of(context)!.noPressureUlcerDescription;
      case PressureUlcerType.category1:
        return AppLocalizations.of(context)!.pressureUlcerCategory1Description;
      case PressureUlcerType.category2:
        return AppLocalizations.of(context)!.pressureUlcerCategory2Description;
      case PressureUlcerType.category3:
        return AppLocalizations.of(context)!.pressureUlcerCategory3Description;
      case PressureUlcerType.category4:
        return AppLocalizations.of(context)!.pressureUlcerCategory4Description;
    }
  }

  Color get color {
    switch (this) {
      case PressureUlcerType.none:
        return AppTheme.colors.error.withOpacity(0);
      case PressureUlcerType.category1:
        return AppTheme.colors.error.withOpacity(0.25);
      case PressureUlcerType.category2:
        return AppTheme.colors.error.withOpacity(0.5);
      case PressureUlcerType.category3:
        return AppTheme.colors.error.withOpacity(0.75);
      case PressureUlcerType.category4:
        return AppTheme.colors.error;
    }
  }
}

enum PressureUlcerLocation {
  other,
  ancle,
  heel,
  insideKnee,
  hip,
  sacrum,
  sitBones,
  scapula,
  shoulder,
}

extension PressureUlcerLocationExtensions on PressureUlcerLocation {
  String displayString(BuildContext context) {
    switch (this) {
      case PressureUlcerLocation.ancle:
        return AppLocalizations.of(context)!.ancle;
      case PressureUlcerLocation.heel:
        return AppLocalizations.of(context)!.heel;
      case PressureUlcerLocation.insideKnee:
        return AppLocalizations.of(context)!.insideKnee;
      case PressureUlcerLocation.hip:
        return AppLocalizations.of(context)!.hip;
      case PressureUlcerLocation.sacrum:
        return AppLocalizations.of(context)!.sacrum;
      case PressureUlcerLocation.sitBones:
        return AppLocalizations.of(context)!.sitBones;
      case PressureUlcerLocation.scapula:
        return AppLocalizations.of(context)!.scapula;
      case PressureUlcerLocation.shoulder:
        return AppLocalizations.of(context)!.shoulder;
      default:
        return AppLocalizations.of(context)!.other;
    }
  }
}

PressureUlcerLocation pressureUlcerLocationFromString(String location) {
  switch (location) {
    case 'ancle':
      return PressureUlcerLocation.ancle;
    case 'heel':
      return PressureUlcerLocation.heel;
    case 'insideKnee':
      return PressureUlcerLocation.insideKnee;
    case 'hip':
      return PressureUlcerLocation.hip;
    case 'sacrum':
      return PressureUlcerLocation.sacrum;
    case 'sitBones':
      return PressureUlcerLocation.sitBones;
    case 'scapula':
      return PressureUlcerLocation.scapula;
    case 'shoulder':
      return PressureUlcerLocation.shoulder;
    default:
      return PressureUlcerLocation.other;
  }
}

class PressureUlcerEntry extends JournalEntry {
  final PressureUlcerType pressureUlcerType;
  final PressureUlcerLocation location;

  PressureUlcerEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.pressureUlcerType,
    required this.location,
  });

  factory PressureUlcerEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    return PressureUlcerEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      pressureUlcerType: pressureUlcerTypefromString(info['pressureUlcerType']),
      location: pressureUlcerLocationFromString(info['location']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'pressureUlcerType': pressureUlcerType.name,
        'location': location.name,
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return PressureUlcerEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      pressureUlcerType: values['pressureUlcerType'] as PressureUlcerType,
      location: values['location'] as PressureUlcerLocation,
    );
  }

  @override
  String title(BuildContext context) {
    return AppLocalizations.of(context)!.pressureUlcer;
  }

  @override
  String shortcutTitle(BuildContext context) {
    return '${AppLocalizations.of(context)!.pressureUlcer} \n${location.displayString(context)}';
  }

  @override
  String get identifier {
    return 'pressureUlcer ${location.name}';
  }

  @override
  TimelineType get timelineType => TimelineType.bladderEmptying;
}
