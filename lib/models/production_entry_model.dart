import 'package:cloud_firestore/cloud_firestore.dart';
import 'production_item_model.dart';

/// ProductionEntry — records a staff member's daily completed items.
class ProductionEntry {
  final String id;
  final String date; // "YYYY-MM-DD"
  final String month; // "YYYY-MM"
  final String staffId;
  final String staffName;
  final double totalAmount;
  final int totalQuantity;
  final List<ProductionItem> items;
  final String? notes;
  final String? createdBy;
  final bool edited;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductionEntry({
    required this.id,
    required this.date,
    required this.month,
    required this.staffId,
    required this.staffName,
    required this.totalAmount,
    required this.totalQuantity,
    required this.items,
    this.notes,
    this.createdBy,
    this.edited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductionEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final itemsList = (data['items'] as List<dynamic>?)
            ?.map((item) => ProductionItem.fromMap(item as Map<String, dynamic>))
            .toList() ??
        [];

    return ProductionEntry(
      id: doc.id,
      date: data['date'] ?? '',
      month: data['month'] ?? '',
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      totalQuantity: data['totalQuantity'] ?? 0,
      items: itemsList,
      notes: data['notes'],
      createdBy: data['createdBy'],
      edited: data['edited'] ?? false,
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
      'totalAmount': totalAmount,
      'totalQuantity': totalQuantity,
      'items': items.map((item) => item.toMap()).toList(),
      'notes': notes,
      'createdBy': createdBy,
      'edited': edited,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
