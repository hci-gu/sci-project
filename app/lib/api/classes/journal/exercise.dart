import 'package:flutter/material.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/gen_l10n/app_localizations.dart';

class ExerciseEntry extends JournalEntry {
  final Activity activity;
  final int minutes;

  ExerciseEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.activity,
    required this.minutes,
  });

  factory ExerciseEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    return ExerciseEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      activity: activityFromString(info['activity']),
      minutes: info['minutes'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'activity': activity.name,
        'minutes': minutes,
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return ExerciseEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      activity: values['activity'] as Activity,
      minutes: values['minutes'] as int,
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

  @override
  TimelineType get timelineType => TimelineType.exercise;
}
