import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiUrl = 'https://sci-api.appadem.in';

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

  Future<List<HeartRate>> getData(DateTime from, DateTime to) async {
    var type = 'hr';
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

  // Use API as a singleton
  static final Api _instance = Api._internal();
  factory Api() {
    return _instance;
  }
  Api._internal();
}
