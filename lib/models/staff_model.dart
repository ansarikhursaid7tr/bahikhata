import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Staff model — represents a worker/employee in an organization.
class Staff {
  final String id;
  final String name;
  final String? phone;
  final StaffType staffType;
  final bool active;
  final String? userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.id,
    required this.name,
    this.phone,
    required this.staffType,
    this.active = true,
    this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Staff.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Staff(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'],
      staffType: StaffType.values.firstWhere(
        (e) => e.name == data['staffType'],
        orElse: () => StaffType.other,
      ),
      active: data['active'] ?? true,
      userId: data['userId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'staffType': staffType.name,
      'active': active,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Staff copyWith({
    String? name,
    String? phone,
    StaffType? staffType,
    bool? active,
    String? userId,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      staffType: staffType ?? this.staffType,
      active: active ?? this.active,
      userId: userId ?? this.userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
