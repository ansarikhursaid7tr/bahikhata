import 'package:cloud_firestore/cloud_firestore.dart';

/// MonthlyRate model — stores rate for an item type for a specific month.
/// Uses composite key logic: one item type has one rate per month.
class MonthlyRate {
  final String id;
  final String month; // "YYYY-MM" format, e.g., "2026-05"
  final String itemTypeId;
  final String itemTypeName;
  final double rate;
  final String? notes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyRate({
    required this.id,
    required this.month,
    required this.itemTypeId,
    required this.itemTypeName,
    required this.rate,
    this.notes,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Generates a composite document ID for uniqueness: one rate per item per month.
  static String generateId(String month, String itemTypeId) {
    return '${month}_$itemTypeId';
  }

  factory MonthlyRate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyRate(
      id: doc.id,
      month: data['month'] ?? '',
      itemTypeId: data['itemTypeId'] ?? '',
      itemTypeName: data['itemTypeName'] ?? '',
      rate: (data['rate'] ?? 0).toDouble(),
      notes: data['notes'],
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'month': month,
      'itemTypeId': itemTypeId,
      'itemTypeName': itemTypeName,
      'rate': rate,
      'notes': notes,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MonthlyRate copyWith({
    double? rate,
    String? notes,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return MonthlyRate(
      id: id,
      month: month,
      itemTypeId: itemTypeId,
      itemTypeName: itemTypeName,
      rate: rate ?? this.rate,
      notes: notes ?? this.notes,
      createdBy: createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
