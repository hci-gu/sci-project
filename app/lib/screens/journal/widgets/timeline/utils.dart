import 'package:flutter/material.dart';
import 'package:scimovement/api/classes/journal/journal.dart';
import 'package:scimovement/models/journal/timeline.dart';

double headerHeight = 48;
double eventHeight = 48;
double chartEventHeight = 140;

enum TimelineMode {
  day,
  week,
  month,
}

TimelineMode activeMode = TimelineMode.month;

double heightForType(TimelineDisplayType type) {
  if (type == TimelineDisplayType.chart) {
    return chartEventHeight;
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
