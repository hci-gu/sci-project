import 'package:flutter/material.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';

double headerHeight = 48;
double eventHeight = 48;
double lineChartHeight = 180;
double barChartHeight = 100;

enum TimelineMode {
  day,
  week,
  month,
}

TimelineMode activeMode = TimelineMode.month;

double heightForType(TimelineDisplayType type) {
  if (type == TimelineDisplayType.lineChart) {
    return lineChartHeight;
  }
  if (type == TimelineDisplayType.barChart) {
    return barChartHeight;
  }
  return eventHeight;
}

double offsetForEvents(List<TimelineType> types, int index) {
  double offset = 48 + 8;

  for (int i = 0; i < index; i++) {
    offset += heightForType(timelineDisplayType(types[i]));
    offset += 8;
  }

  return offset;
}

double pageWidth(BuildContext context) {
  return MediaQuery.of(context).size.width / 2;
}
