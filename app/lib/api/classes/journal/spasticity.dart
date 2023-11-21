import 'package:flutter/material.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SpasticityEntry extends JournalEntry {
  final int level;

  SpasticityEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.level,
  });

  factory SpasticityEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    return SpasticityEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      level: info['minutes'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'level': level,
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return SpasticityEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      level: values['level'] as int,
    );
  }

  @override
  String title(BuildContext context) {
    return AppLocalizations.of(context)!.exercise;
  }

  @override
  String shortcutTitle(BuildContext context) {
    return title(context);
  }
}
