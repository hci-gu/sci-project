import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:scimovement/models/config.dart';
import 'package:timezone/standalone.dart' as tz;

const String apiUrl = 'https://sci-api.prod.appadem.in';
// const String apiUrl = 'http://192.168.0.33:4000';
// const String apiUrl = 'http://localhost:4000';

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

class Api {
  String _userId = '';
  String tz = 'Europe/Stockholm';
  Dio dio = Dio(BaseOptions(
    baseUrl: apiUrl,
    connectTimeout: 30000,
    receiveTimeout: 45000,
  ));

  void clearUserId() {
    _userId = '';
  }

  Future<User?> login(String email, String password) async {
    var response = await dio.post('/users/login', data: {
      'email': email,
      'password': password,
    });
    User user = User.fromJson(response.data);
    _userId = user.id;

    return user;
  }

  Future<User?> getUser(String id) async {
    var response = await dio.get('/users/$id');

    if (response.statusCode != 200) return null;

    User user = User.fromJson(response.data);
    _userId = user.id;

    return user;
  }

  Future<List<Energy>> getEnergy(
    DateTime from,
    DateTime to,
    ChartMode mode,
  ) async {
    Map<String, String> params = {
      'from': from.toIso8601String().substring(0, 16),
      'to': to.toIso8601String().substring(0, 16),
    };
    if (mode != ChartMode.day) {
      params['group'] = chartModeToGroup(mode);
    }
    var response = await dio.get('/energy/$_userId', queryParameters: params);

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => Energy.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Bout>> getBouts(
      DateTime from, DateTime to, ChartMode mode) async {
    Map<String, String> params = {
      'from': from.toIso8601String().substring(0, 16),
      'to': to.toIso8601String().substring(0, 16),
    };
    if (mode != ChartMode.day) {
      params['group'] = chartModeToGroup(mode);
    }
    var response = await dio.get('/bouts/$_userId', queryParameters: params);

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => Bout.fromJson(json)).toList();
    }
    return [];
  }

  Future<int> getActivity(DateTime from, DateTime to) async {
    var response = await dio.get('/sedentary/$_userId', queryParameters: {
      'from': from.toIso8601String().substring(0, 16),
      'to': to.toIso8601String().substring(0, 16),
    });

    if (response.statusCode == 200) {
      Map<String, dynamic> data = response.data;
      try {
        double value = data['averageInactiveDuration'] ?? 0.0;
        return value.round();
      } catch (e) {
        return data['averageInactiveDuration'] ?? 0;
      }
    }
    return 0;
  }

  Future<User?> updateUser(Map<String, dynamic> userdata) async {
    try {
      await dio.patch(
        '/users/$_userId',
        data: userdata,
      );
    } catch (e) {
      print(e);
    }

    return getUser(_userId);
  }

  String chartModeToGroup(ChartMode mode) {
    switch (mode) {
      case ChartMode.week:
      case ChartMode.month:
        return 'day';
      case ChartMode.year:
        return 'month';
      default:
        return 'hour';
    }
  }

  // Use API as a singleton
  static final Api _instance = Api._internal();
  factory Api() {
    return _instance;
  }
  Api._internal();
}
