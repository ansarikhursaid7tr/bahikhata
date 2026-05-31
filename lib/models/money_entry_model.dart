import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// MoneyEntry — records money movements (advance, payment, deduction, bonus).
class MoneyEntry {
  final String id;
  final String date; // "YYYY-MM-DD"
  final String month; // "YYYY-MM"
  final String staffId;
  final String staffName;
  final MoneyEntryType type;
  final double amount;
  final MoneyEffect effect;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MoneyEntry({
    required this.id,
    required this.date,
    required this.month,
    required this.staffId,
    required this.staffName,
    required this.type,
    required this.amount,
    MoneyEffect? effect,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  }) : effect = effect ?? type.effect;

  factory MoneyEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MoneyEntry(
      id: doc.id,
      date: data['date'] ?? '',
      month: data['month'] ?? '',
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
      type: MoneyEntryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MoneyEntryType.other,
      ),
      amount: (data['amount'] ?? 0).toDouble(),
      effect: MoneyEffect.values.firstWhere(
        (e) => e.name == data['effect'],
        orElse: () => MoneyEffect.decreasePayable,
      ),
      notes: data['notes'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'month': month,
      'staffId': staffId,
      'staffName': staffName,
      'type': type.name,
      'amount': amount,
      'effect': effect.name,
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
