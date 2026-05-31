import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// Organization model — the top-level entity scoping all data.
class Organization {
  final String id;
  final String name;
  final String ownerId;
  final BusinessType businessType;
  final String currency;
  final String? logoBase64;
  final String calendarType; // 'AD' or 'BS'
  final String? address;
  final String? contact;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.businessType,
    this.currency = '\$',
    this.logoBase64,
    this.calendarType = 'AD',
    this.address,
    this.contact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Organization.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Organization(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      businessType: BusinessType.values.firstWhere(
        (e) => e.name == data['businessType'],
        orElse: () => BusinessType.other,
      ),
      currency: data['currency'] ?? '\$',
      logoBase64: data['logoBase64'],
      calendarType: data['calendarType'] ?? 'AD',
      address: data['address'],
      contact: data['contact'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'businessType': businessType.name,
      'currency': currency,
      'logoBase64': logoBase64,
      'calendarType': calendarType,
      'address': address,
      'contact': contact,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Organization copyWith({
    String? name,
    String? ownerId,
    BusinessType? businessType,
    String? currency,
    String? logoBase64,
    String? calendarType,
    String? address,
    String? contact,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      businessType: businessType ?? this.businessType,
      currency: currency ?? this.currency,
      logoBase64: logoBase64 ?? this.logoBase64,
      calendarType: calendarType ?? this.calendarType,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
