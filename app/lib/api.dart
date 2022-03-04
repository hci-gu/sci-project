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
      weight: json['weight'],
    );
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

  Future getData() async {
    print(_userId);
  }

  // Use API as a singleton
  static final Api _instance = Api._internal();
  factory Api() {
    return _instance;
  }
  Api._internal();
}
