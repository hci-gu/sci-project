import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:scimovement/models/energy.dart';

const String apiUrl = 'https://sci-api.appadem.in';
// const String apiUrl = 'http://localhost:4000';

class User {
  final String id;
  final double weight;

  User({
    required this.id,
    required this.weight,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      weight: json['weight'].toDouble(),
    );
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

class Energy {
  final DateTime time;
  final double value;

  Energy(this.time, this.value);

  factory Energy.fromJson(Map<String, dynamic> json) {
    double value = json['energy'] != null ? json['energy'].toDouble() : 0.0;
    return Energy(DateTime.parse(json['t']), value);
  }
}

class Accel {
  final DateTime time;
  final double x;
  final double y;
  final double z;

  Accel(this.time, this.x, this.y, this.z);

  factory Accel.fromJson(Map<String, dynamic> json) {
    return Accel(DateTime.parse(json['t']), json['x'], json['y'], json['z']);
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

  Future<List<HeartRate>> getData(
      DateTime from, DateTime to, String type) async {
    var query =
        'from=${from.toIso8601String()}&to=${to.toIso8601String()}&group=minute';
    var url = Uri.parse('$apiUrl/users/$_userId/data/$type?$query');
    var response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.map((json) => HeartRate.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Energy>> getEnergy(
    DateTime from,
    DateTime to,
    EnergyParams params,
  ) async {
    var response = await dio.get('/users/$_userId/energy', queryParameters: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
      ...params.toQueryParams(),
    });

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      return data.map((json) => Energy.fromJson(json)).toList();
    }
    return [];
  }

  // Use API as a singleton
  static final Api _instance = Api._internal();
  factory Api() {
    return _instance;
  }
  Api._internal();
}
