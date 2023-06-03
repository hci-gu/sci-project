import 'package:flutter/material.dart';
import 'package:scimovement/api/api.dart';
import 'package:intl/intl.dart';
import 'package:scimovement/theme/theme.dart';
import 'package:timezone/standalone.dart' as tz;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum Gender { male, female }

enum BodyPartType { neck, back, scapula, shoulderJoint, elbow, hand }

enum Side { left, right }

class BodyPart {
  BodyPartType type;
  Side? side;

  BodyPart(this.type, this.side);

  factory BodyPart.fromString(String bodyPartString) {
    final parts = bodyPartString.split('-');
    BodyPartType type =
        bodyPartTypeFromString(parts.first) ?? BodyPartType.neck;
    Side? side = sideFromString(parts.last);
    return BodyPart(type, side);
  }

  @override
  String toString() {
    if (type == BodyPartType.neck || type == BodyPartType.back) {
      return type.name;
    }
    return '${type.name}${side != null ? '-${side!.name}' : ''}';
  }

  String displayString(BuildContext context) {
    if (type == BodyPartType.neck || type == BodyPartType.back) {
      return type.displayString(context);
    }
    return '${side != null ? '${side!.displayString(context)} ' : ''}${type.displayString(context)}';
  }

  @override
  int get hashCode => type.hashCode ^ side.hashCode;

  @override
  bool operator ==(other) =>
      other is BodyPart && other.type == type && other.side == side;
}

extension SideDisplayAsString on Side {
  String displayString(BuildContext context) {
    switch (this) {
      case Side.left:
        return AppLocalizations.of(context)!.left;
      case Side.right:
        return AppLocalizations.of(context)!.right;
    }
  }
}

Side? sideFromString(String side) {
  switch (side) {
    case 'left':
      return Side.left;
    case 'right':
      return Side.right;
    default:
      return null;
  }
}

extension BodyPartTypeDisplayAsString on BodyPartType {
  String displayString(BuildContext context) {
    switch (this) {
      case BodyPartType.neck:
        return AppLocalizations.of(context)!.bodyPartNeck;
      case BodyPartType.back:
        return AppLocalizations.of(context)!.bodyPartBack;
      case BodyPartType.scapula:
        return AppLocalizations.of(context)!.bodyPartScapula;
      case BodyPartType.shoulderJoint:
        return AppLocalizations.of(context)!.bodyPartShoulderJoint;
      case BodyPartType.elbow:
        return AppLocalizations.of(context)!.bodyPartElbow;
      case BodyPartType.hand:
        return AppLocalizations.of(context)!.bodyPartHand;
      default:
        return toString();
    }
  }
}

BodyPartType? bodyPartTypeFromString(String bodyPartString) {
  switch (bodyPartString) {
    case 'neck':
      return BodyPartType.neck;
    case 'back':
      return BodyPartType.back;
    case 'scapula':
      return BodyPartType.scapula;
    case 'shoulderJoint':
      return BodyPartType.shoulderJoint;
    case 'elbow':
      return BodyPartType.elbow;
    case 'hand':
      return BodyPartType.hand;
    default:
      return null;
  }
}

Gender genderFromString(String gender) {
  if (gender == 'female') {
    return Gender.female;
  }
  return Gender.male;
}

enum Condition { paraplegic, tetraplegic }

extension ConditionDisplayAsString on Condition {
  String displayString(BuildContext context) {
    switch (this) {
      case Condition.paraplegic:
        return AppLocalizations.of(context)!.paraplegic;
      case Condition.tetraplegic:
        return AppLocalizations.of(context)!.tetraplegic;
      default:
        return toString();
    }
  }
}

Condition conditionFromString(String condition) {
  if (condition == 'tetraplegic') {
    return Condition.tetraplegic;
  }
  return Condition.paraplegic;
}

class NotificationSettings {
  final bool activity;
  final bool data;
  final bool journal;

  NotificationSettings({
    this.activity = false,
    this.data = false,
    this.journal = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      activity: json['activity'] ?? false,
      data: json['data'] ?? false,
      journal: json['journal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
      'data': data,
      'journal': journal,
    };
  }
}

class User {
  final String id;
  final String? email;
  final double? weight;
  final Gender? gender;
  final Condition? condition;
  final int? injuryLevel;
  final String? deviceId;
  final bool hasData;
  final NotificationSettings notificationSettings;

  User({
    required this.id,
    required this.notificationSettings,
    this.email,
    this.weight,
    this.gender,
    this.condition,
    this.injuryLevel,
    this.hasData = true,
    this.deviceId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      weight: json['weight'] != null ? json['weight'].toDouble() : 0,
      gender: json['gender'] != null ? genderFromString(json['gender']) : null,
      condition: json['condition'] != null
          ? conditionFromString(json['condition'])
          : null,
      injuryLevel: json['injuryLevel'] ?? 0,
      deviceId: json['deviceId'] ?? '',
      hasData: json['hasData'] ?? false,
      notificationSettings: json['notificationSettings'] != null
          ? NotificationSettings.fromJson(json['notificationSettings'])
          : NotificationSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'gender': gender.toString(),
      'condition': condition.toString(),
      'injuryLevel': injuryLevel,
    };
  }
}

enum Activity {
  sedentary,
  moving,
  active,
  skiErgo,
  armErgo,
  weights,
  rollOutside
}

extension ActivityDisplayString on Activity {
  String displayString(BuildContext context) {
    switch (this) {
      case Activity.sedentary:
        return AppLocalizations.of(context)!.sedentary;
      case Activity.moving:
        return AppLocalizations.of(context)!.movement;
      case Activity.active:
        return AppLocalizations.of(context)!.active;
      case Activity.weights:
        return AppLocalizations.of(context)!.weights;
      case Activity.skiErgo:
        return AppLocalizations.of(context)!.skiErgo;
      case Activity.armErgo:
        return AppLocalizations.of(context)!.armErgo;
      case Activity.rollOutside:
        return AppLocalizations.of(context)!.rollOutside;
      default:
        return toString();
    }
  }
}

extension ActivityGroupValue on Activity {
  int get group {
    switch (this) {
      case Activity.sedentary:
        return 0;
      case Activity.moving:
        return 1;
      case Activity.active:
      case Activity.weights:
      case Activity.skiErgo:
      case Activity.armErgo:
      case Activity.rollOutside:
        return 2;
      default:
        return 0;
    }
  }
}

extension ActivityIsExercise on Activity {
  bool get isExercise {
    switch (this) {
      case Activity.weights:
      case Activity.skiErgo:
      case Activity.armErgo:
      case Activity.rollOutside:
        return true;
      default:
        return false;
    }
  }
}

Activity activityFromString(string) {
  switch (string) {
    case 'sedentary':
      return Activity.sedentary;
    case 'moving':
      return Activity.moving;
    case 'active':
      return Activity.active;
    case 'weights':
      return Activity.weights;
    case 'skiErgo':
      return Activity.skiErgo;
    case 'armErgo':
      return Activity.armErgo;
    case 'rollOutside':
      return Activity.rollOutside;
    default:
      return Activity.moving;
  }
}

class Energy {
  final DateTime time;
  final double value;
  final int minutes;
  final Activity activity;

  Energy({
    required this.time,
    required this.value,
    this.minutes = 1,
    this.activity = Activity.sedentary,
  });

  factory Energy.fromJson(Map<String, dynamic> json) {
    double value = json['kcal'] != null ? json['kcal'].toDouble() : 0.0;
    Activity activity = activityFromString(json['activity']);
    String minutesString = json['minutes']?.toString() ?? '1';
    return Energy(
      time: tz.TZDateTime.parse(tz.getLocation(Api().tz), json['t']),
      value: value,
      activity: activity,
      minutes: int.parse(minutesString),
    );
  }
}

class Bout {
  final int id;
  final DateTime time;
  final int minutes;
  final Activity activity;

  Bout(
      {required this.id,
      required this.time,
      required this.minutes,
      required this.activity});

  factory Bout.fromJson(Map<String, dynamic> json) {
    String minutesString = json['minutes'].toString();

    return Bout(
      id: json['id'] ?? -1,
      time: tz.TZDateTime.parse(tz.getLocation(Api().tz), json['t']),
      minutes: double.parse(minutesString).toInt(),
      activity: activityFromString(json['activity']),
    );
  }

  String get displayDuration {
    DateTime from = time;
    DateTime to = time.add(Duration(minutes: minutes));
    // HH:mm - HH:mm
    return '${from.hour.toString().padLeft(2, '0')}:${from.minute.toString().padLeft(2, '0')} - ${to.hour.toString().padLeft(2, '0')}:${to.minute.toString().padLeft(2, '0')}, ${DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(time)}';
  }
}

enum JournalType {
  pain,
  pressureRelease,
  pressureUlcer,
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
    return '';
  }

  String shortcutTitle(BuildContext context) {
    return '';
  }

  JournalEntry fromFormUpdate(Map<String, dynamic> values) => this;

  String get identifier => '';
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
          values['bodyPartType'] as BodyPartType, values['side'] as Side?),
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
}

enum PressureReleaseExercise {
  forwards,
  rightSide,
  leftSide,
  lying,
}

PressureReleaseExercise prExerciseFromString(String string) {
  switch (string) {
    case 'forwards':
      return PressureReleaseExercise.forwards;
    case 'rightSide':
      return PressureReleaseExercise.rightSide;
    case 'leftSide':
      return PressureReleaseExercise.leftSide;
    case 'lying':
      return PressureReleaseExercise.lying;
    default:
      return PressureReleaseExercise.forwards;
  }
}

extension PressureReleaseExerciseExtension on PressureReleaseExercise {
  String get asset {
    switch (this) {
      case PressureReleaseExercise.forwards:
        return 'assets/images/pressure_release_forward.jpeg';
      case PressureReleaseExercise.rightSide:
        return 'assets/images/pressure_release_right.jpeg';
      case PressureReleaseExercise.leftSide:
        return 'assets/images/pressure_release_left.jpeg';
      case PressureReleaseExercise.lying:
        return 'assets/images/pressure_release_lying.jpeg';
    }
  }

  String displayString(BuildContext context) {
    switch (this) {
      case PressureReleaseExercise.forwards:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLeanForward;
      case PressureReleaseExercise.rightSide:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLeanRight;
      case PressureReleaseExercise.leftSide:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLeanLeft;
      case PressureReleaseExercise.lying:
        return AppLocalizations.of(context)!.pressureReleaseExerciseLying;
    }
  }

  String description(BuildContext context) {
    switch (this) {
      case PressureReleaseExercise.forwards:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLeanForwardDescription;
      case PressureReleaseExercise.rightSide:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLeanRightDescription;
      case PressureReleaseExercise.leftSide:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLeanLeftDescription;
      case PressureReleaseExercise.lying:
        return AppLocalizations.of(context)!
            .pressureReleaseExerciseLyingDescription;
    }
  }
}

class PressureReleaseEntry extends JournalEntry {
  final List<PressureReleaseExercise> exercises;

  PressureReleaseEntry({
    required super.id,
    required super.time,
    required super.type,
    required super.comment,
    required this.exercises,
  });

  factory PressureReleaseEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> info = json['info'];
    List<dynamic> exercises = info['exercises'];

    return PressureReleaseEntry(
      id: json['id'],
      time: DateTime.parse(json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'] ?? '',
      exercises: exercises.map((e) => prExerciseFromString(e)).toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'info': {
        'exercises': exercises
            .map(
              (e) => e.name.toString(),
            )
            .toList(),
      }
    };
  }

  @override
  JournalEntry fromFormUpdate(Map<String, dynamic> values) {
    return PressureReleaseEntry(
      id: id,
      type: type,
      time: values['time'] as DateTime,
      comment: values['comment'] as String,
      exercises: values['exercises'] as List<PressureReleaseExercise>,
    );
  }

  @override
  String title(BuildContext context) {
    return 'Tryckavlastning';
  }

  @override
  String shortcutTitle(BuildContext context) {
    return title(context);
  }

  @override
  String get identifier {
    return 'pressureRelease';
  }
}

enum PressureUlcerType {
  none,
  category1,
  category2,
  category3,
  category4,
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
      pressureUlcerType: PressureUlcerType.values.firstWhere(
          (e) => e.name == info['pressureUlcerType'],
          orElse: () => PressureUlcerType.category1),
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
}
