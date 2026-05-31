import 'package:flutter/material.dart';
import 'package:nepali_date_picker/nepali_date_picker.dart';
import 'package:nepali_utils/nepali_utils.dart';
import '../utils/date_utils.dart';

class AppDatePicker {
  static Future<String?> show(
    BuildContext context, {
    required String calendarType,
    required String initialDate,
  }) async {
    if (calendarType == 'BS') {
      final parts = initialDate.split('-');
      NepaliDateTime initial;
      if (parts.length == 3) {
        initial = NepaliDateTime(
          int.tryParse(parts[0]) ?? 2080,
          int.tryParse(parts[1]) ?? 1,
          int.tryParse(parts[2]) ?? 1,
        );
      } else {
        initial = NepaliDateTime.now();
      }

      final picked = await showNepaliDatePicker(
        context: context,
        initialDate: initial,
        firstDate: NepaliDateTime(2000),
        lastDate: NepaliDateTime(2100),
      );

      if (picked != null) {
        return '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      }
    } else {
      DateTime initial = AppDateUtils.parseDate(initialDate);
      
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        return '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      }
    }
    return null;
  }
}
