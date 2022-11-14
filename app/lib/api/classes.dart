import 'package:scimovement/api/api.dart';
import 'package:timezone/standalone.dart' as tz;

enum Gender { male, female }

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

class User {
  final String id;
  final String? email;
  final double? weight;
  final Gender? gender;
  final Condition? condition;
  final int? injuryLevel;
  final String? deviceId;

  User({
    required this.id,
    this.email,
    this.weight,
    this.gender,
    this.condition,
    this.injuryLevel,
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
