import 'package:cloud_firestore/cloud_firestore.dart';

/// ItemType model — represents a type of work item (e.g., Coat, Pant, Shirt).
/// Designed to be flexible for any business type.
class ItemType {
  final String id;
  final String name;
  final String? category;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemType({
    required this.id,
    required this.name,
    this.category,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemType.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemType(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'],
      active: data['active'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ItemType copyWith({
    String? name,
    String? category,
    bool? active,
    DateTime? updatedAt,
  }) {
    return ItemType(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
