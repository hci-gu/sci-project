import 'package:scimovement/api/api.dart';
import 'package:timezone/standalone.dart' as tz;

enum Gender { male, female }

enum BodyPart { neck, scapula, shoulderJoint, elbow, hand }

enum Arm { left, right }

extension ArmDisplayAsString on Arm {
  String displayString() {
    switch (this) {
      case Arm.left:
        return 'Vänster';
      case Arm.right:
        return 'Höger';
    }
  }
}

Arm? armFromString(String arm) {
  switch (arm) {
    case 'left':
      return Arm.left;
    case 'right':
      return Arm.right;
    default:
      return null;
  }
}

extension BodyPartDisplayAsString on BodyPart {
  String displayString() {
    switch (this) {
      case BodyPart.neck:
        return 'Nacke';
      case BodyPart.scapula:
        return 'Skulderblad';
      case BodyPart.shoulderJoint:
        return 'Axelled';
      case BodyPart.elbow:
        return 'Armbåge';
      case BodyPart.hand:
        return 'Hand';
      default:
        return toString();
    }
  }
}

BodyPart? bodyPartFromString(String bodyPartString) {
  switch (bodyPartString) {
    case 'neck':
      return BodyPart.neck;
    case 'scapula':
      return BodyPart.scapula;
    case 'shoulderJoint':
      return BodyPart.shoulderJoint;
    case 'elbow':
      return BodyPart.elbow;
    case 'hand':
      return BodyPart.hand;
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
    this.hasData = false,
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
}

extension ActivityDisplayString on Activity {
  String displayString() {
    switch (this) {
      case Activity.sedentary:
        return 'Stillasittande';
      case Activity.moving:
        return 'Rörelse';
      case Activity.active:
        return 'Aktiv';
      default:
        return toString();
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
  final DateTime time;
  final int minutes;
  final Activity activity;

  Bout({required this.time, required this.minutes, required this.activity});

  factory Bout.fromJson(Map<String, dynamic> json) {
    String minutesString = json['minutes'].toString();

    return Bout(
      time: tz.TZDateTime.parse(tz.getLocation(Api().tz), json['t']),
      minutes: double.parse(minutesString).toInt(),
      activity: activityFromString(json['activity']),
    );
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
  final Arm? arm;

  JournalEntry({
    required this.id,
    required this.time,
    required this.type,
    required this.comment,
    required this.painLevel,
    required this.bodyPart,
    this.arm,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    String bodyPartString = json['bodyPart'];
    final parts = bodyPartString.split('-');
    BodyPart bodyPart = bodyPartFromString(parts.first) ?? BodyPart.neck;
    Arm? arm = armFromString(parts.last);

    return JournalEntry(
      id: json['id'],
      time: tz.TZDateTime.parse(tz.getLocation(Api().tz), json['t']),
      type: journalTypeFromString(json['type']),
      comment: json['comment'],
      painLevel: json['painLevel'],
      bodyPart: bodyPart,
      arm: arm,
    );
  }
}
