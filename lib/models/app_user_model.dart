import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// App user model — maps Firebase Auth users to organization roles.
class AppUser {
  final String id;
  final String uid;
  final String? staffId;
  final String name;
  final String email;
  final String username;
  final UserRole role;
  final bool active;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.uid,
    this.staffId,
    required this.name,
    required this.email,
    required this.username,
    required this.role,
    this.active = true,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      uid: data['uid'] ?? '',
      staffId: data['staffId'],
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => UserRole.staff,
      ),
      active: data['active'] ?? true,
      organizationId: data['organizationId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'staffId': staffId,
      'name': name,
      'email': email,
      'username': username,
      'role': role.name,
      'active': active,
      'organizationId': organizationId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AppUser copyWith({
    String? staffId,
    String? name,
    String? email,
    String? username,
    UserRole? role,
    bool? active,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      uid: uid,
      staffId: staffId ?? this.staffId,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      active: active ?? this.active,
      organizationId: organizationId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
