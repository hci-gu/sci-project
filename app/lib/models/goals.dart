import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';
import 'package:scimovement/models/pagination.dart';
import 'package:timezone/standalone.dart' as tz;

enum TimeFrame {
  day,
  week,
  month,
  year,
}

String startToString(Duration start) {
  String hour = start.inHours.toString().padLeft(2, '0');
  String minute = start.inMinutes.remainder(60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

class Goal {
  final int id;
  final int value;
  final int progress;
  final DateTime reminder;
  final TimeFrame timeFrame;
  final Duration start;
  final Duration recurrence;

  Goal({
    required this.id,
    required this.value,
    required this.progress,
    required this.reminder,
    required this.start,
    required this.recurrence,
    this.timeFrame = TimeFrame.day,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    String hour = json['start'].toString().substring(0, 2);
    String minute = json['start'].toString().substring(3, 5);
    return Goal(
      id: json['id'],
      value: json['value'],
      progress: json['progress'],
      reminder: DateTime.parse(json['reminder']),
      recurrence: Duration(minutes: json['recurrence']),
      start: Duration(hours: int.parse(hour), minutes: int.parse(minute)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'start': startToString(start),
    };
  }
}

class JournalGoal extends Goal {
  final JournalType type;

  JournalGoal({
    required super.id,
    required super.value,
    required super.progress,
    required super.reminder,
    required super.start,
    required super.recurrence,
    super.timeFrame,
    required this.type,
  });

  factory JournalGoal.fromJson(Map<String, dynamic> json) {
    String hour = json['start'].toString().substring(0, 2);
    String minute = json['start'].toString().substring(3, 5);
    String dateString = json['reminder'];
    DateTime reminder = DateTime.parse(dateString.replaceAll('Z', ''));
    return JournalGoal(
      id: json['id'],
      value: json['value'],
      progress: json['progress'],
      reminder: reminder,
      start: Duration(hours: int.parse(hour), minutes: int.parse(minute)),
      recurrence: Duration(minutes: json['recurrence']),
      type: journalTypeFromString(json['journalType']),
    );
  }
}

final goalsProvider =
    FutureProvider.family<List<Goal>, Pagination>((ref, pagination) async {
  ref.watch(updateJournalProvider);
  ref.watch(updateGoalProvider);
  DateTime date = ref.watch(dateProvider);

  return Api().getGoals(pagination.from(date));
});

final journalGoalsProvider =
    FutureProvider.family<List<JournalGoal>, Pagination>(
        (ref, pagination) async {
  final goals = await ref.watch(goalsProvider(pagination).future);

  return goals.whereType<JournalGoal>().toList();
});

final journalGoalProvider =
    FutureProvider.family<JournalGoal?, Pagination>((ref, pagination) async {
  List<JournalGoal> goals =
      await ref.watch(journalGoalsProvider(pagination).future);

  return goals.firstWhereOrNull((e) => e.type == JournalType.pressureRelease);
});

class GoalState extends StateNotifier<DateTime> {
  GoalState() : super(DateTime.now());

  Future createGoal(Map<String, dynamic> values) async {
    Duration start = values['start'] as Duration;
    await Api().createGoal({
      'type': 'journal',
      'journalType': 'pressureRelease',
      'timeFrame': 'day',
      'value': values['value'] as int,
      'start': startToString(start),
    });
    state = DateTime.now();
  }

  Future updateGoal(Goal goal) async {
    await Api().updateGoal(goal);
    state = DateTime.now();
  }

  Future deleteGoal(int id) async {
    await Api().deleteGoal(id);
    state = DateTime.now();
  }
}

final updateGoalProvider =
    StateNotifierProvider<GoalState, DateTime>((ref) => GoalState());
