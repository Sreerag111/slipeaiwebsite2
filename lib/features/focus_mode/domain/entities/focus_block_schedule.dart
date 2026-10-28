import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Days of week, Sunday-first to match the client's design (S M T W T F S).
enum Weekday { sun, mon, tue, wed, thu, fri, sat }

extension WeekdayLabel on Weekday {
  String get shortLabel {
    switch (this) {
      case Weekday.sun:
        return 'Sun';
      case Weekday.mon:
        return 'Mon';
      case Weekday.tue:
        return 'Tue';
      case Weekday.wed:
        return 'Wed';
      case Weekday.thu:
        return 'Thu';
      case Weekday.fri:
        return 'Fri';
      case Weekday.sat:
        return 'Sat';
    }
  }

  /// Single-letter label for the day pills, e.g. 'S', 'M', 'T'...
  String get initial {
    switch (this) {
      case Weekday.sun:
        return 'S';
      case Weekday.mon:
        return 'M';
      case Weekday.tue:
        return 'T';
      case Weekday.wed:
        return 'W';
      case Weekday.thu:
        return 'T';
      case Weekday.fri:
        return 'F';
      case Weekday.sat:
        return 'S';
    }
  }

  bool get isWeekday => this != Weekday.sun && this != Weekday.sat;
}

const Set<Weekday> kWeekdays = {
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
};

/// A single app's block schedule: a time range + the days it applies to.
class FocusBlockSchedule {
  const FocusBlockSchedule({
    required this.start,
    required this.end,
    required this.days,
  });

  final TimeOfDay start;
  final TimeOfDay end;
  final Set<Weekday> days;

  FocusBlockSchedule copyWith({
    TimeOfDay? start,
    TimeOfDay? end,
    Set<Weekday>? days,
  }) {
    return FocusBlockSchedule(
      start: start ?? this.start,
      end: end ?? this.end,
      days: days ?? this.days,
    );
  }

  /// e.g. "5:00 PM - 6:00 PM"
  String formatRange(BuildContext context) {
    final l = MaterialLocalizations.of(context);
    return '${l.formatTimeOfDay(start, alwaysUse24HourFormat: false)} - '
        '${l.formatTimeOfDay(end, alwaysUse24HourFormat: false)}';
  }

  bool get isValid => days.isNotEmpty;
}

/// Simple model for a blockable app shown in the list.
class BlockableApp {
  const BlockableApp({
    required this.id,
    required this.name,
    this.icon,
    this.iconColor,
    this.iconBytes,
  });

  /// The Android package name (e.g. 'com.instagram.android') - used as the
  /// lookup key for schedules and for talking to the native side.
  final String id;
  final String name;

  /// Fallback Material icon, used only if [iconBytes] is null (e.g. while
  /// the real icon list is still loading).
  final IconData? icon;
  final Color? iconColor;

  /// Real app icon PNG bytes, returned by FocusModeNativeService.
  final Uint8List? iconBytes;
}
