import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

extension ParseToString on Condition {
  String displayString() {
    switch (this) {
      case Condition.paraplegic:
        return 'Paraplegic';
      case Condition.tetraplegic:
        return 'Tetraplegic';
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
  final double? weight;
  final Gender? gender;
  final Condition? condition;
  final int? injuryLevel;

  User({
    required this.id,
    this.weight,
    this.gender,
    this.condition,
    this.injuryLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      weight: json['weight'] != null ? json['weight'].toDouble() : 0,
      gender: json['gender'] != null ? genderFromString(json['gender']) : null,
      condition: json['condition'] != null
          ? conditionFromString(json['condition'])
          : null,
      injuryLevel: json['injuryLevel'] ?? 0,
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

class HeartRate {
  final DateTime time;
  final double value;

  HeartRate(this.time, this.value);

  factory HeartRate.fromJson(Map<String, dynamic> json) {
    return HeartRate(DateTime.parse(json['t']), json['hr'].toDouble());
  }
}

enum ActivityLevel {
  sedentary,
  movement,
  active,
}

class Energy {
  final DateTime time;
  final double value;
  final ActivityLevel activityLevel;

  Energy(this.time, this.value, [this.activityLevel = ActivityLevel.sedentary]);

  factory Energy.fromJson(Map<String, dynamic> json) {
    double value = json['energy'] != null ? json['energy'].toDouble() : 0.0;
    ActivityLevel activityLevel;

    if (json['activityLevel'] == 'sedentary') {
      activityLevel = ActivityLevel.sedentary;
    } else if (json['activityLevel'] == 'high-activity') {
      activityLevel = ActivityLevel.active;
    } else {
      activityLevel = ActivityLevel.movement;
    }
    return Energy(DateTime.parse(json['t']), value, activityLevel);
  }
}

class Accel {
  final DateTime time;
  final double x;
  final double y;
  final double z;
  final double a;

  Accel(this.time, this.x, this.y, this.z, this.a);

  factory Accel.fromJson(Map<String, dynamic> json) {
    // calculate a from x, y, z
    double a = sqrt(pow(json['x'].toDouble(), 2) +
        pow(json['y'].toDouble(), 2) +
        pow(json['z'].toDouble(), 2));
    return Accel(DateTime.parse(json['t']), json['x'], json['y'], json['z'], a);
  }
}

class Api {
  String _userId = '';
  Dio dio = Dio(BaseOptions(
    baseUrl: apiUrl,
    connectTimeout: 5000,
    receiveTimeout: 45000,
  ));

  void clearUserId() {
    _userId = '';
  }

  Future<User?> getUser(String id) async {
    var url = Uri.parse('$apiUrl/users/$id');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 404) return null;

    _userId = id;

    return User.fromJson(json.decode(response.body));
  }

  Future<List<HeartRate>> getHeartRate(DateTime from, DateTime to) async {
    var response = await dio.get('/users/$_userId/data/hr', queryParameters: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'group': 'minute',
    });

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => HeartRate.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Accel>> getAccel(DateTime from, DateTime to) async {
    var response =
        await dio.get('/users/$_userId/data/accel', queryParameters: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      'group': 'second',
    });

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => Accel.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Energy>> getEnergy(
    DateTime from,
    DateTime to,
  ) async {
    var response = await dio.get('/users/$_userId/energy', queryParameters: {
      'from': DateFormat('yyyy-MM-dd HH:mm').format(from),
      'to': DateFormat('yyyy-MM-dd HH:mm').format(to),
    });

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => Energy.fromJson(json)).toList();
    }
    return [];
  }

  Future<int> getActivity(DateTime from, DateTime to) async {
    var response = await dio.get('/users/$_userId/activity', queryParameters: {
      'from': DateFormat('yyyy-MM-dd HH:mm').format(from),
      'to': DateFormat('yyyy-MM-dd HH:mm').format(to),
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

  // Use API as a singleton
  static final Api _instance = Api._internal();
  factory Api() {
    return _instance;
  }
  Api._internal();
}
