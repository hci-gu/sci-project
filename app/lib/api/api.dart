import 'package:dio/dio.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/bowel_emptying.dart';
import 'package:scimovement/api/classes/journal/exercise.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/api/classes/journal/spasticity.dart';
import 'package:scimovement/models/goals.dart';
import 'package:scimovement/models/pagination.dart';

const String apiUrl = 'https://sci-api.prod.appadem.in';
// const String apiUrl = 'http://192.168.10.100:4000';
// const String apiUrl = 'http://localhost:4000';
const emptyBody = {};

class Api {
  String _userId = '';
  String tz = 'Europe/Stockholm';
  Dio dio = Dio(BaseOptions(
    baseUrl: apiUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
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

  Future<User?> register(String email, String password,
      [Map<dynamic, dynamic> values = emptyBody]) async {
    Map<dynamic, dynamic> body = {
      'email': email,
      'password': password,
      ...values,
    };
    var response = await dio.post('/users', data: body);
    User user = User.fromJson(response.data);
    _userId = user.id;

    return user;
  }

  Future deleteAccount() => dio.delete('/users/$_userId');

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

  Future createBout(DateTime time, int minutes, Activity activity) async {
    var response = await dio.post('/bouts/$_userId', data: {
      't': time.toIso8601String(),
      'minutes': minutes,
      'activity': activity.name,
    });
  }

  Future deleteBout(int id) async {
    await dio.delete('/bouts/$_userId/$id');
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
    userdata.removeWhere((key, value) => value == null);
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

  Future<List<JournalEntry>> getJournalForType(
      JournalType type, DateTime date) async {
    try {
      var response =
          await dio.get('/journal/$_userId/${type.name}', queryParameters: {
        'to': date.toIso8601String().substring(0, 16),
      });
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) {
          JournalType type = journalTypeFromString(json['type']);
          switch (type) {
            case JournalType.musclePain:
            case JournalType.neuropathicPain:
              return PainLevelEntry.fromJson(json);
            case JournalType.pressureRelease:
              return PressureReleaseEntry.fromJson(json);
            case JournalType.pressureUlcer:
              return PressureUlcerEntry.fromJson(json);
            case JournalType.bladderEmptying:
              return BladderEmptyingEntry.fromJson(json);
            case JournalType.bowelEmptying:
              return BowelEmptyingEntry.fromJson(json);
            case JournalType.urinaryTractInfection:
              return UTIEntry.fromJson(json);
            case JournalType.exercise:
              return ExerciseEntry.fromJson(json);
            case JournalType.spasticity:
              return SpasticityEntry.fromJson(json);
            default:
              return JournalEntry.fromJson(json);
          }
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<JournalEntry>> getJournal(
    DateTime from,
    DateTime to,
    ChartMode mode,
  ) async {
    try {
      var response = await dio.get('/journal/$_userId', queryParameters: {
        'from': from.toIso8601String().substring(0, 16),
        'to': to.toIso8601String().substring(0, 16),
      });
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) {
          JournalType type = journalTypeFromString(json['type']);
          switch (type) {
            case JournalType.musclePain:
            case JournalType.neuropathicPain:
              return PainLevelEntry.fromJson(json);
            case JournalType.pressureRelease:
              return PressureReleaseEntry.fromJson(json);
            case JournalType.pressureUlcer:
              return PressureUlcerEntry.fromJson(json);
            case JournalType.bladderEmptying:
              return BladderEmptyingEntry.fromJson(json);
            case JournalType.bowelEmptying:
              return BowelEmptyingEntry.fromJson(json);
            case JournalType.urinaryTractInfection:
              return UTIEntry.fromJson(json);
            case JournalType.exercise:
              return ExerciseEntry.fromJson(json);
            case JournalType.spasticity:
              return SpasticityEntry.fromJson(json);
            default:
              return JournalEntry.fromJson(json);
          }
        }).toList();
      }
    } catch (e) {
      print(e);
    }
    return [];
  }

  Future createJournalEntry(Map<String, dynamic> form) async {
    await dio.post('/journal/$_userId', data: form);
  }

  Future updateJournalEntry(JournalEntry entry) async {
    await dio.patch('/journal/$_userId/${entry.id}', data: entry.toJson());
  }

  Future deleteJournalEntry(int id) async {
    await dio.delete('/journal/$_userId/$id');
  }

  Future<List<Goal>> getGoals(DateTime date) async {
    try {
      var response = await dio.get('/goals/$_userId', queryParameters: {
        'date': date.toIso8601String().substring(0, 16),
      });
      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((json) {
          String type = json['type'];

          if (type == 'journal') {
            return JournalGoal.fromJson(json);
          }

          return Goal.fromJson(json);
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  Future createGoal(Map<String, dynamic> form) async {
    await dio.post('/goals/$_userId', data: form);
  }

  Future updateGoal(Goal goal) async {
    await dio.patch('/goals/$_userId/${goal.id}', data: goal.toJson());
  }

  Future deleteGoal(int id) async {
    await dio.delete('/goals/$_userId/$id');
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
