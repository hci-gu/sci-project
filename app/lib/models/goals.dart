import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/api.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/models/journal.dart';

enum TimeFrame {
  day,
  week,
  month,
  year,
}

class Goal {
  final int id;
  final int value;
  final int progress;
  final TimeFrame timeFrame;

  Goal({
    required this.id,
    required this.value,
    required this.progress,
    this.timeFrame = TimeFrame.day,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      value: json['value'],
      progress: json['progress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }
}

class JournalGoal extends Goal {
  final JournalType type;

  JournalGoal({
    required super.id,
    required super.value,
    required super.progress,
    super.timeFrame,
    required this.type,
  });

  factory JournalGoal.fromJson(Map<String, dynamic> json) {
    return JournalGoal(
      id: json['id'],
      value: json['value'],
      progress: json['progress'],
      type: journalTypeFromString(json['journalType']),
    );
  }
}

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  ref.watch(updateJournalProvider);

  return Api().getGoals();
});

final journalGoalsProvider = FutureProvider<List<JournalGoal>>((ref) async {
  final goals = await ref.watch(goalsProvider.future);

  return goals.whereType<JournalGoal>().toList();
});

final journalGoalProvider =
    FutureProvider.family<JournalGoal?, JournalType>((ref, type) async {
  List<JournalGoal> goals = await ref.watch(journalGoalsProvider.future);

  return goals.firstWhereOrNull((e) => e.type == type);
});
