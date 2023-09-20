import 'package:flutter/material.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum UTIType { none, feeling, diagnosed }

extension UTITypeExtension on UTIType {
  String displayString(BuildContext context) {
    switch (this) {
      case UTIType.none:
        return AppLocalizations.of(context)!.utiTypeNone;
      case UTIType.feeling:
        return AppLocalizations.of(context)!.utiTypeFeeling;
      case UTIType.diagnosed:
        return AppLocalizations.of(context)!.utiTypeDiagnosed;
    }
  }

  String description(BuildContext context) {
    switch (this) {
      case UTIType.none:
        return AppLocalizations.of(context)!.utiTypeNoneDescription;
      case UTIType.feeling:
        return AppLocalizations.of(context)!.utiTypeFeelingDescription;
      case UTIType.diagnosed:
        return AppLocalizations.of(context)!.utiTypeDiagnosedDescription;
    }
  }

  Color color() {
    switch (this) {
      case UTIType.none:
        return AppTheme.colors.error.withOpacity(0);
      case UTIType.feeling:
        return AppTheme.colors.error.withOpacity(0.33);
      case UTIType.diagnosed:
        return AppTheme.colors.error.withOpacity(0.66);
    }
  }
}

UTIType utiTypefromString(String type) {
  switch (type) {
    case 'none':
      return UTIType.none;
    case 'feeling':
      return UTIType.feeling;
    case 'diagnosed':
      return UTIType.diagnosed;
    default:
      return UTIType.none;
  }
}

class UTIEntry extends JournalEntry {
  final UTIType utiType;

  UTIEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.utiType,
  });

  factory UTIEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    return UTIEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      utiType: utiTypefromString(info['utiType'] ?? 'none'),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'utiType': utiType.name,
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return UTIEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      utiType: values['utiType'] as UTIType,
    );
  }

  @override
  String title(BuildContext context) {
    switch (utiType) {
      case UTIType.none:
        return AppLocalizations.of(context)!.utiTypeNone;
      case UTIType.feeling:
        return AppLocalizations.of(context)!.utiTypeFeeling;
      case UTIType.diagnosed:
        return AppLocalizations.of(context)!.utiTypeDiagnosed;
    }
  }

  @override
  String shortcutTitle(BuildContext context) {
    return title(context);
  }
}
