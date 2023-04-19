import 'package:scimovement/api/api.dart';
import 'package:intl/intl.dart';
import 'package:timezone/standalone.dart' as tz;

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

  String displayString() {
    if (type == BodyPartType.neck || type == BodyPartType.back) {
      return type.displayString();
    }
    return '${side != null ? '${side!.displayString()} ' : ''}${type.displayString()}';
  }

  @override
  int get hashCode => type.hashCode ^ side.hashCode;

  @override
  bool operator ==(other) =>
      other is BodyPart && other.type == type && other.side == side;
}

extension SideDisplayAsString on Side {
  String displayString() {
    switch (this) {
      case Side.left:
        return 'Vänster';
      case Side.right:
        return 'Höger';
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
  String displayString() {
    switch (this) {
      case BodyPartType.neck:
        return 'Nacke';
      case BodyPartType.back:
        return 'Rygg';
      case BodyPartType.scapula:
        return 'Skulderblad';
      case BodyPartType.shoulderJoint:
        return 'Axelled';
      case BodyPartType.elbow:
        return 'Armbåge';
      case BodyPartType.hand:
        return 'Hand';
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
  String displayString() {
    switch (this) {
      case Condition.paraplegic:
        return 'Paraplegi';
      case Condition.tetraplegic:
        return 'Tetraplegi';
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

enum Activity { sedentary, moving, active, skiErgo, armErgo, weights }

extension ActivityDisplayString on Activity {
  String displayString() {
    switch (this) {
      case Activity.sedentary:
        return 'Stillasittande';
      case Activity.moving:
        return 'Rörelse';
      case Activity.active:
        return 'Aktiv';
      case Activity.weights:
        return 'Vikter';
      case Activity.skiErgo:
        return 'Ski Ergometer';
      case Activity.armErgo:
        return 'Armcykel';
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
}

JournalType journalTypeFromString(String type) {
  if (type == 'pain') {
    return JournalType.pain;
  }
  return JournalType.pain;
}

class JournalEntry {
  final int id;
  final DateTime time;
  final JournalType type;
  final String comment;
  final int painLevel;
  final BodyPart bodyPart;

  JournalEntry({
    required this.id,
    required this.time,
    required this.type,
    required this.comment,
    required this.painLevel,
    required this.bodyPart,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      time: tz.TZDateTime.parse(tz.getLocation(Api().tz), json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      painLevel: json['painLevel'],
      bodyPart: BodyPart.fromString(json['bodyPart']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      't': time.toIso8601String(),
      'type': type.name,
      'comment': comment,
      'painLevel': painLevel,
      'bodyPart': bodyPart.toString(),
    };
  }
}
