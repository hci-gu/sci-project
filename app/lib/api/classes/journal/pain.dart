import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:flutter/material.dart';

enum PainType {
  muscleAndJoints,
  neuropathic,
}

class PainLevelEntry extends JournalEntry {
  final int painLevel;
  final BodyPart bodyPart;

  PainLevelEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.painLevel,
    required this.bodyPart,
  });

  factory PainLevelEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];

    return PainLevelEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      painLevel: info['painLevel'],
      bodyPart: BodyPart.fromString(info['bodyPart']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'painLevel': painLevel,
        'bodyPart': bodyPart.toString(),
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return PainLevelEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      painLevel: values['painLevel'] as int,
      bodyPart: BodyPart(
        values['bodyPartType'] as BodyPartType,
        values['side'] as Side?,
      ),
    );
  }

  @override
  String title(BuildContext context) {
    return '${painLevel.toString()} - ${bodyPart.displayString(context)}';
  }

  @override
  String shortcutTitle(BuildContext context) {
    return bodyPart.displayString(context);
  }

  @override
  String get identifier {
    return bodyPart.toString();
  }

  @override
  TimelineType get timelineType => TimelineType.pain;
}
