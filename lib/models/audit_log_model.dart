import 'package:cloud_firestore/cloud_firestore.dart';

/// AuditLog — tracks changes for accountability.
class AuditLog {
  final String id;
  final String action;
  final String collectionName;
  final String documentId;
  final Map<String, dynamic>? oldValue;
  final Map<String, dynamic>? newValue;
  final String performedBy;
  final DateTime performedAt;

  AuditLog({
    required this.id,
    required this.action,
    required this.collectionName,
    required this.documentId,
    this.oldValue,
    this.newValue,
    required this.performedBy,
    required this.performedAt,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      action: data['action'] ?? '',
      collectionName: data['collectionName'] ?? '',
      documentId: data['documentId'] ?? '',
      oldValue: data['oldValue'] as Map<String, dynamic>?,
      newValue: data['newValue'] as Map<String, dynamic>?,
      performedBy: data['performedBy'] ?? '',
      performedAt:
          (data['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'collectionName': collectionName,
      'documentId': documentId,
      'oldValue': oldValue,
      'newValue': newValue,
      'performedBy': performedBy,
      'performedAt': Timestamp.fromDate(performedAt),
    };
  }
}
