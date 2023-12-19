import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:scimovement/api/classes.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/api/classes/journal/spasticity.dart';
import 'package:scimovement/models/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';
import 'package:scimovement/screens/journal/widgets/body_part_icon.dart';
import 'package:scimovement/theme/theme.dart';

TimelineChartItem itemForEntry(JournalEntry entry) {
  return TimelineChartItem(
    category: categoryForEntry(entry),
    x: entry.time.millisecondsSinceEpoch.toDouble(),
    y: entry is PainLevelEntry
        ? entry.painLevel.toDouble()
        : entry is SpasticityEntry
            ? entry.level.toDouble()
            : 0,
  );
}

Category categoryForEntry(JournalEntry entry) {
  return Category(
    name: entry is PainLevelEntry
        ? entry.bodyPart.toString()
        : entry.type.toString(),
    title: entry is PainLevelEntry
        ? entry.bodyPart.displayString
        : entry.type.displayString,
    color: entry is PainLevelEntry
        ? AppTheme.colors.bodyPartToColor(entry.bodyPart)
        : Colors.brown,
    icon: entry is PainLevelEntry
        ? BodyPartIcon(bodyPart: entry.bodyPart, size: 16)
        : SvgPicture.asset(
            'assets/svg/spasticity.svg',
            height: 16,
          ),
    isStepLine: entry.type == JournalType.neuropathicPain ||
        entry.type == JournalType.spasticity,
  );
}

class Category {
  String name;
  Function title;
  Color color;
  Widget icon;
  final bool isStepLine;

  Category({
    required this.name,
    required this.title,
    required this.color,
    required this.icon,
    this.isStepLine = false,
  });

  int get sort {
    if (isStepLine) return 10;
    return 0;
  }

  @override
  bool operator ==(other) => other is Category && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class TimelineChartItem {
  final Category category;
  final double x;
  final double y;

  TimelineChartItem({
    required this.category,
    required this.x,
    required this.y,
  });
}

String categoryIdentifierForEntry(JournalEntry entry) {
  if (entry is PainLevelEntry) {
    return entry.bodyPart.toString();
  }
  return entry.type.toString();
}

final timelineLineChartProvider =
    FutureProvider.family<List<JournalEntry>, TimelinePage>((ref, page) async {
  DateTime from = page.pagination.from;
  DateTime to = page.pagination.to;
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  if (journal.length == 1 || journal.isEmpty) {
    return journal;
  }

  List<JournalEntry> entries = [
    ...journal.whereType<PainLevelEntry>().toList(),
    ...journal.whereType<SpasticityEntry>().toList(),
  ];

  List<JournalEntry> entriesToShow = entries
      .where((e) => e.time.isBefore(to) && e.time.isAfter(from))
      .toList();

  List<String> categories =
      entries.map((e) => categoryIdentifierForEntry(e)).toSet().toList();
  for (String category in categories) {
    List<JournalEntry> entriesForCategory = entries
        .where((e) => categoryIdentifierForEntry(e) == category)
        .toList();

    List<JournalEntry> entriesBefore =
        entriesForCategory.where((e) => e.time.isBefore(from)).toList();
    entriesBefore.sort((a, b) {
      int aDistance = a.time.difference(from).inMilliseconds.abs();
      int bDistance = b.time.difference(from).inMilliseconds.abs();
      return aDistance.compareTo(bDistance);
    });

    List<JournalEntry> entriesAfter =
        entriesForCategory.where((e) => e.time.isAfter(to)).toList();
    entriesAfter.sort((a, b) {
      int aDistance = a.time.difference(to).inMilliseconds.abs();
      int bDistance = b.time.difference(to).inMilliseconds.abs();
      return aDistance.compareTo(bDistance);
    });

    if (entriesBefore.isNotEmpty) {
      entriesToShow.add(entriesBefore.first);
    }
    if (entriesAfter.isNotEmpty) {
      entriesToShow.add(entriesAfter.first);
    }
  }

  DateTime today = DateTime.now();
  List<JournalEntry> finalEntries = [];
  for (String category in categories) {
    List<JournalEntry> entriesForCategory = entriesToShow
        .where((e) => categoryIdentifierForEntry(e) == category)
        .toList();
    entriesForCategory.sort((a, b) => b.time.compareTo(a.time));

    Map<String, bool> days = Map.fromIterable(
        entriesForCategory
            .map((e) => e.time.toIso8601String().substring(0, 10)),
        value: (e) => false);

    for (JournalEntry entry in entriesForCategory) {
      String day = entry.time.toIso8601String().substring(0, 10);
      if (days[day] == false) {
        finalEntries.add(entry);
        days[day] = true;
      }
    }
    JournalEntry lastEntry = entriesForCategory.last;
    if (entryShouldExtend(lastEntry) && !isSameDay(lastEntry.time, today)) {
      finalEntries.add(lastEntry.copyWith(updateTime: today));
    }
  }

  finalEntries.sort((a, b) => a.time.compareTo(b.time));
  return finalEntries;
});

bool entryShouldExtend(JournalEntry entry) {
  if (entry is PainLevelEntry) {
    return entry.bodyPart.type == BodyPartType.allodynia ||
        entry.bodyPart.type == BodyPartType.neuropathic ||
        entry.bodyPart.type == BodyPartType.intermittentNeuroPathic;
  }

  return entry is SpasticityEntry;
}

final timelineLineChartCategoriesForVisibleRange =
    FutureProvider<List<Category>>((ref) async {
  List<DateTime> visibleRange = ref.watch(timelineVisibleRangeProvider);
  List<JournalEntry> journal = await ref.watch(timelineDataProvider.future);

  List<Category> categories = journal
      .where((e) =>
          e.type == JournalType.musclePain ||
          e.type == JournalType.neuropathicPain ||
          e.type == JournalType.spasticity)
      .where((e) =>
          e.time.isAfter(visibleRange.first) &&
          e.time.isBefore(visibleRange.last))
      .map((e) => categoryForEntry(e))
      .toSet()
      .toList();
  categories.sort((a, b) => a.sort - b.sort);
  return categories;
});
