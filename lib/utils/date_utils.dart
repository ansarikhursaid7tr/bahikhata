import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

/// Date utility functions for BahiKhata.
/// Supports both AD (Gregorian) and BS (Nepali) calendars.
class AppDateUtils {
  AppDateUtils._();

  // Internal AD formatters
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _monthFormat = DateFormat('yyyy-MM');
  static final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _displayMonthFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');

  /// Gets today's date as a string (yyyy-MM-dd)
  static String today({String calendarType = 'AD'}) {
    if (calendarType == 'BS') {
      final now = NepaliDateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
    return _dateFormat.format(DateTime.now());
  }

  /// Gets current month as a string (yyyy-MM)
  static String currentMonth({String calendarType = 'AD'}) {
    if (calendarType == 'BS') {
      final now = NepaliDateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
    return _monthFormat.format(DateTime.now());
  }

  /// Extracts month (yyyy-MM) from a date string (yyyy-MM-dd)
  static String getMonthFromDateString(String dateStr) {
    if (dateStr.length >= 7) return dateStr.substring(0, 7);
    return dateStr;
  }

  /// Formats for display: "10 May 2026" or "10 Jestha 2083"
  static String displayDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final year = int.tryParse(parts[0]) ?? 2000;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    
    if (year > 2050) { // BS Date
      final bsMonthNames = ['', 'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'];
      final mName = (month >= 1 && month <= 12) ? bsMonthNames[month] : month.toString();
      return '$day $mName $year';
    } else { // AD Date
      try {
        final d = DateTime.parse(dateStr);
        return _displayDateFormat.format(d);
      } catch (_) {
        return dateStr;
      }
    }
  }

  /// Formats for display: "May 2026" or "Jestha 2083"
  static String displayMonth(String monthStr) {
    final parts = monthStr.split('-');
    if (parts.length != 2) return monthStr;
    final year = int.tryParse(parts[0]) ?? 2000;
    final month = int.tryParse(parts[1]) ?? 1;

    if (year > 2050) { // BS
      final bsMonthNames = ['', 'Baisakh', 'Jestha', 'Ashadh', 'Shrawan', 'Bhadra', 'Ashwin', 'Kartik', 'Mangsir', 'Poush', 'Magh', 'Falgun', 'Chaitra'];
      final mName = (month >= 1 && month <= 12) ? bsMonthNames[month] : month.toString();
      return '$mName $year';
    } else {
      try {
        final d = DateTime.parse('$monthStr-01');
        return _displayMonthFormat.format(d);
      } catch (_) {
        return monthStr;
      }
    }
  }

  /// Parses "YYYY-MM-DD" to DateTime.
  /// Used mostly for sorting or local comparisons where exact time doesn't matter.
  static DateTime parseDate(String dateStr) {
    try {
      return _dateFormat.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Short date: "10 May" or "10 Jes"
  static String shortDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final year = int.tryParse(parts[0]) ?? 2000;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;

    if (year > 2050) { // BS
      final bsMonthNames = ['', 'Bai', 'Jes', 'Ash', 'Shr', 'Bha', 'Ash', 'Kar', 'Man', 'Pou', 'Mag', 'Fal', 'Cha'];
      final mName = (month >= 1 && month <= 12) ? bsMonthNames[month] : month.toString();
      return '$day $mName';
    } else {
      try {
        final d = DateTime.parse(dateStr);
        return _shortDateFormat.format(d);
      } catch (_) {
        return dateStr;
      }
    }
  }

  /// Gets the previous month string: "2026-05" → "2026-04" or "2083-02" -> "2083-01"
  static String previousMonth(String monthStr) {
    final parts = monthStr.split('-');
    if (parts.length != 2) return monthStr;
    int year = int.tryParse(parts[0]) ?? 2000;
    int month = int.tryParse(parts[1]) ?? 1;

    month -= 1;
    if (month < 1) {
      month = 12;
      year -= 1;
    }
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  /// Gets all months between two dates (inclusive) based on calendar strings (e.g. 2026-01 to 2026-05)
  static List<String> getMonthRange(String startMonth, String endMonth) {
    final months = <String>[];
    String current = startMonth;
    
    while (current.compareTo(endMonth) <= 0) {
      months.add(current);
      
      final parts = current.split('-');
      int y = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
      current = '$y-${m.toString().padLeft(2, '0')}';
    }
    return months;
  }
}
